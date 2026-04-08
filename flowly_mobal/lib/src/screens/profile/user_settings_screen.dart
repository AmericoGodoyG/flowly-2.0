import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meu_app/src/app/flowly_theme.dart';
import 'package:meu_app/src/core/config/api_config.dart';
import 'package:meu_app/src/core/constants/storage_keys.dart';
import 'package:meu_app/src/core/network/api_client.dart';
import 'package:meu_app/src/widgets/flowly_button.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String _userEmail = '';
  String _fotoPerfil = '';
  XFile? _novaFoto;
  bool _isLoadingUserData = false;
  bool _isChangingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoadingUserData = true);
    try {
      final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
        '/api/users/me',
      );
      final Map<String, dynamic> data = response.data ?? <String, dynamic>{};

      final name = (data['nome'] ?? '').toString();
      final email = (data['email'] ?? '').toString();
      final fotoPerfil = (data['fotoPerfil'] ?? '').toString();

      await _storage.write(key: StorageKeys.userName, value: name);
      await _storage.write(key: StorageKeys.userEmail, value: email);
      await _storage.write(key: StorageKeys.userPhoto, value: fotoPerfil);

      setState(() {
        _nameController.text = name;
        _userEmail = email;
        _fotoPerfil = fotoPerfil;
      });
    } catch (e) {
      _showMessage('Erro ao carregar dados', isError: true);
    } finally {
      setState(() => _isLoadingUserData = false);
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showMessage('Preencha todos os campos', isError: true);
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showMessage('As senhas não conferem', isError: true);
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showMessage(
        'A nova senha deve ter no mínimo 6 caracteres',
        isError: true,
      );
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      await ApiClient.instance.dio.put<void>(
        '/api/users/me/password',
        data: <String, String>{
          'senhaAtual': _currentPasswordController.text,
          'novaSenha': _newPasswordController.text,
        },
      );

      if (!mounted) return;

      _showMessage('Senha alterada com sucesso!', isError: false);
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (error) {
      _showMessage(ApiClient.mapError(error).message, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    final String nome = _nameController.text.trim();
    if (nome.isEmpty) {
      _showMessage('Nome é obrigatório', isError: true);
      return;
    }

    setState(() => _isLoadingUserData = true);
    try {
      final FormData formData = FormData.fromMap(<String, dynamic>{
        'nome': nome,
        if (_novaFoto != null)
          'fotoPerfil': await MultipartFile.fromFile(
            _novaFoto!.path,
            filename: _novaFoto!.name,
          ),
      });

      final response = await ApiClient.instance.dio.put<Map<String, dynamic>>(
        '/api/users/me',
        data: formData,
      );

      final Map<String, dynamic> body = response.data ?? <String, dynamic>{};
      final Map<String, dynamic> user =
          (body['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final String fotoPerfil = (user['fotoPerfil'] ?? _fotoPerfil).toString();

      await _storage.write(key: StorageKeys.userName, value: nome);
      await _storage.write(key: StorageKeys.userPhoto, value: fotoPerfil);
      setState(() {
        _fotoPerfil = fotoPerfil;
        _novaFoto = null;
      });
      _showMessage('Perfil atualizado com sucesso!', isError: false);
    } catch (error) {
      _showMessage(ApiClient.mapError(error).message, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoadingUserData = false);
      }
    }
  }

  Future<void> _selecionarFoto() async {
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _novaFoto = picked);
  }

  String _buildFotoUrl() {
    if (_fotoPerfil.isEmpty) {
      return '';
    }
    if (_fotoPerfil.startsWith('http')) {
      return _fotoPerfil;
    }
    return '${ApiConfig.baseUrl}$_fotoPerfil';
  }

  ImageProvider<Object>? _buildFotoProvider() {
    if (_novaFoto != null) {
      return FileImage(File(_novaFoto!.path));
    }
    final String fotoUrl = _buildFotoUrl();
    if (fotoUrl.isEmpty) {
      return null;
    }
    return NetworkImage(fotoUrl);
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFC62828)
            : const Color(0xFF0D9C6E),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Configurações'),
          centerTitle: true,
          elevation: 0,
          bottom: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.person), text: 'Dados'),
              Tab(icon: Icon(Icons.lock), text: 'Senha'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Dados Pessoais Tab
            _buildUserDataTab(),
            // Alterar Senha Tab
            _buildChangePasswordTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _isLoadingUserData
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Email (Read-only)
                Text(
                  'Email',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  enabled: false,
                  controller: TextEditingController(text: _userEmail),
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: const Icon(Icons.email),
                    filled: true,
                    fillColor: flowlySurfaceAlt,
                  ),
                ),
                const SizedBox(height: 24),
                // User Name
                Text(
                  'Nome Completo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person),
                    hintText: 'Digite seu nome completo',
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Foto de Perfil',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: flowlyPrimary,
                      backgroundImage: _buildFotoProvider(),
                      child: _buildFotoProvider() == null
                          ? Text(
                              _nameController.text.isNotEmpty
                                  ? _nameController.text[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _selecionarFoto,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Escolher foto'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Info Message
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: flowlyAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: flowlyAccent.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: flowlyAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Atualizações de dados em desenvolvimento',
                          style: TextStyle(color: flowlyText, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FlowlyButton(
                  onPressed: _isLoadingUserData ? () {} : _updateProfile,
                  label: _isLoadingUserData
                      ? 'Salvando...'
                      : 'Salvar alterações',
                  isLoading: _isLoadingUserData,
                ),
              ],
            ),
    );
  }

  Widget _buildChangePasswordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instruction
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: flowlyWarning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: flowlyWarning.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.security, color: flowlyWarning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Use uma senha forte com pelo menos 6 caracteres',
                    style: TextStyle(color: flowlyText, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Current Password
          Text(
            'Senha Atual',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _currentPasswordController,
            obscureText: _obscureCurrentPassword,
            decoration: InputDecoration(
              labelText: 'Senha atual',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCurrentPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(
                  () => _obscureCurrentPassword = !_obscureCurrentPassword,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // New Password
          Text(
            'Nova Senha',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _newPasswordController,
            obscureText: _obscureNewPassword,
            decoration: InputDecoration(
              labelText: 'Nova senha',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscureNewPassword = !_obscureNewPassword),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Confirm Password
          Text(
            'Confirmar Senha',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirmar senha',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Change Password Button
          FlowlyButton(
            onPressed: _isChangingPassword ? () {} : () => _changePassword(),
            label: _isChangingPassword ? 'Alterando...' : 'Alterar Senha',
            isLoading: _isChangingPassword,
          ),
        ],
      ),
    );
  }
}
