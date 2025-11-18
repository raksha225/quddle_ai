import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/classifieds_service.dart';
import '../../services/wallet_service.dart';
import '../../utils/constants/colors.dart';

class PostClassifiedScreen extends StatefulWidget {
  const PostClassifiedScreen({super.key});

  @override
  State<PostClassifiedScreen> createState() => _PostClassifiedScreenState();
}

class _PostClassifiedScreenState extends State<PostClassifiedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  
  String? _selectedCategory;
  List<File> _images = [];
  bool _isLoading = false;
  double? _walletBalance;

  final List<String> _categories = [
    'Electronics',
    'Furniture',
    'Vehicles',
    'Real Estate',
    'Fashion',
    'Sports',
    'Books',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    final result = await WalletService.getWallet();
    if (result['success'] && mounted) {
      setState(() {
        _walletBalance = double.tryParse(result['wallet']['balance'].toString());
      });
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    
    if (pickedFiles != null && pickedFiles.length <= 5) {
      setState(() {
        _images = pickedFiles.map((xFile) => File(xFile.path)).toList();
      });
    } else if (pickedFiles != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 images allowed')),
      );
    }
  }

  Future<void> _postAd() async {
    if (!_formKey.currentState!.validate()) return;

    if (_walletBalance == null || _walletBalance! < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient balance. You need AED 50 to post an ad.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ClassifiedsService.postClassified(
      title: _titleController.text,
      description: _descriptionController.text,
      price: double.tryParse(_priceController.text),
      category: _selectedCategory,
      location: _locationController.text,
      imageCount: _images.length,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      // Upload images if any
      if (_images.isNotEmpty && result['uploadUrls'] != null) {
        await ClassifiedsService.uploadImages(
          classifiedId: result['classified']['id'],
          images: _images,
          uploadUrls: List<Map<String, dynamic>>.from(result['uploadUrls']),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Ad posted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to post ad'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.bgColor,
      appBar: AppBar(
        title: const Text('Post Classified Ad', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (_walletBalance != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Chip(
                avatar: const Icon(Icons.account_balance_wallet, size: 18, color: MyColors.primary),
                label: Text(
                  'AED ${_walletBalance!.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                ),
                backgroundColor: MyColors.primary.withOpacity(0.1),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Posting fee notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MyColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MyColors.primary),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: MyColors.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Posting Fee: AED 50.00\nThis amount will be deducted from your wallet.',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Title
              const Text('Title *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Enter ad title',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: MyColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Title is required' : null,
              ),

              const SizedBox(height: 16),

              // Description
              const Text('Description *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Describe your item',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: MyColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 4,
                validator: (v) => v?.isEmpty ?? true ? 'Description is required' : null,
              ),

              const SizedBox(height: 16),

              // Price
              const Text('Price (AED)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Enter price',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.currency_exchange, color: MyColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: MyColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              // Category
              const Text('Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Select category',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: MyColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(color: Colors.black87)));
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),

              const SizedBox(height: 16),

              // Location
              const Text('Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Enter location',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.location_on, color: MyColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: MyColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              // Images
              const Text('Images (Max 5)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              
              if (_images.isEmpty)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[600]),
                        const SizedBox(height: 8),
                        Text('Tap to add images', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                color: Colors.white,
                                child: Image.file(_images[index], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _images.removeAt(index));
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_photo_alternate, color: MyColors.primary),
                      label: const Text('Change Images', style: TextStyle(color: MyColors.primary)),
                    ),
                  ],
                ),

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _postAd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Post Ad (AED 50)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}