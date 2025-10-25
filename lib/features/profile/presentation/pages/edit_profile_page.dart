import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/services/firebase_storage_service.dart';
import '../../../../shared/services/firebase_bypass_auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _linkController = TextEditingController();
  final _locationController = TextEditingController();
  
  String? _profileImageUrl;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _linkController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = FirebaseBypassAuthService.currentUserId;
      if (userId == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _usernameController.text = data['username'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _linkController.text = data['link'] ?? '';
          _locationController.text = data['location'] ?? '';
          _profileImageUrl = data['photoURL'];
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingImage = true);

      final userId = FirebaseBypassAuthService.currentUserId;
      if (userId == null) return;

      // Upload to Firebase Storage
      final imageUrl = await FirebaseStorageService.uploadProfileImage(
        imagePath: image.path,
        userId: userId,
      );

      if (imageUrl != null) {
        setState(() => _profileImageUrl = imageUrl);
        
        // Update Firestore immediately
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'photoURL': imageUrl});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil fotoğrafı güncellendi')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseBypassAuthService.currentUserId;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'link': _linkController.text.trim(),
        'location': _locationController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundColor : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Kaydet',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading && _usernameController.text.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Picture
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? Colors.grey[800] : Colors.grey[300],
                              image: _profileImageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_profileImageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              border: Border.all(
                                color: AppTheme.primaryColor,
                                width: 3,
                              ),
                            ),
                            child: _profileImageUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                                  )
                                : null,
                          ),
                          if (_isUploadingImage)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black54,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _isUploadingImage ? null : _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? Colors.grey[900]! : Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    
                    Text(
                      'Fotoğrafı değiştirmek için tıklayın',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Username
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Kullanıcı Adı',
                      icon: Icons.person_outline,
                      hint: 'kullanici_adi',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Kullanıcı adı gereklidir';
                        }
                        if (value.trim().length < 3) {
                          return 'Kullanıcı adı en az 3 karakter olmalıdır';
                        }
                        return null;
                      },
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    // Bio
                    _buildTextField(
                      controller: _bioController,
                      label: 'Bio',
                      icon: Icons.notes,
                      hint: 'Müzik zevkinizi anlatın...',
                      maxLines: 4,
                      maxLength: 150,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    // Link
                    _buildTextField(
                      controller: _linkController,
                      label: 'Website / Link',
                      icon: Icons.link,
                      hint: 'https://...',
                      keyboardType: TextInputType.url,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    // Location
                    _buildTextField(
                      controller: _locationController,
                      label: 'Konum',
                      icon: Icons.location_on_outlined,
                      hint: 'İstanbul, Türkiye',
                      isDark: isDark,
                    ),

                    const SizedBox(height: 32),

                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Profiliniz herkese açık olacaktır. Kişisel bilgilerinizi paylaşırken dikkatli olun.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        counterStyle: TextStyle(
          color: isDark ? Colors.grey[500] : Colors.grey[600],
          fontSize: 11,
        ),
      ),
    );
  }
}
