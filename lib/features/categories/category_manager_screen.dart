import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketledger/app/theme.dart';
import 'package:pocketledger/models/category_model.dart';
import 'package:pocketledger/services/category_service.dart';

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> with SingleTickerProviderStateMixin {
  final CategoryService _categoryService = CategoryService();
  late TabController _tabController;

  // Modern Premium Colors to Choose From
  final List<Color> _pickerColors = [
    const Color(0xFF2D6A4F), // Emerald Green
    const Color(0xFF52B788), // Mint Green
    const Color(0xFFE63946), // Coral/Red
    const Color(0xFFF72585), // Soft Pink
    const Color(0xFF4361EE), // Indigo Blue
    const Color(0xFF4CC9F0), // Sky Blue
    const Color(0xFFF7B801), // Golden Amber
    const Color(0xFF7209B7), // Purple
    const Color(0xFF008080), // Teal
    const Color(0xFF7B7B7B), // Slate Grey
  ];

  // Curated Material Icons to Choose From
  final List<IconData> _pickerIcons = [
    Icons.category_rounded,
    Icons.home_rounded,
    Icons.restaurant_rounded,
    Icons.directions_bus_rounded,
    Icons.favorite_rounded,
    Icons.person_rounded,
    Icons.payments_rounded,
    Icons.work_rounded,
    Icons.store_rounded,
    Icons.shopping_bag_rounded,
    Icons.fitness_center_rounded,
    Icons.movie_rounded,
    Icons.school_rounded,
    Icons.flight_rounded,
    Icons.medical_services_rounded,
    Icons.build_rounded,
    Icons.pets_rounded,
    Icons.coffee_rounded,
    Icons.fastfood_rounded,
    Icons.local_grocery_store_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEditCategoryModal([CategoryModel? existingCategory]) {
    final isEditing = existingCategory != null;
    final nameController = TextEditingController(text: existingCategory?.name ?? '');
    IconData selectedIcon = isEditing
        ? IconData(existingCategory!.iconCode, fontFamily: 'MaterialIcons')
        : _pickerIcons.first;
    Color selectedColor = isEditing
        ? Color(existingCategory!.colorValue)
        : _pickerColors.first;
    String selectedType = isEditing ? existingCategory!.type : (_tabController.index == 0 ? 'expense' : 'income');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50, height: 5,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Category' : 'Create Category',
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textBlack),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: AppColors.textBlack),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Form Field: Name
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textBlack, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Category Name',
                    labelStyle: GoogleFonts.outfit(color: AppColors.textGrey),
                    filled: true,
                    fillColor: AppColors.pageBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),

                // Category Type Select
                Text('Category Type', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedType = 'expense'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedType == 'expense' ? Colors.redAccent.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selectedType == 'expense' ? Colors.redAccent : Colors.grey.shade300),
                          ),
                          alignment: Alignment.center,
                          child: Text('Expense', style: GoogleFonts.outfit(color: selectedType == 'expense' ? Colors.redAccent : AppColors.textGrey, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedType = 'income'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedType == 'income' ? AppColors.primaryGreen.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selectedType == 'income' ? AppColors.primaryGreen : Colors.grey.shade300),
                          ),
                          alignment: Alignment.center,
                          child: Text('Income', style: GoogleFonts.outfit(color: selectedType == 'income' ? AppColors.primaryGreen : AppColors.textGrey, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Horizontal Icon Picker
                Text('Select Icon', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pickerIcons.length,
                    itemBuilder: (context, idx) {
                      final icon = _pickerIcons[idx];
                      final isSelected = selectedIcon.codePoint == icon.codePoint;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedIcon = icon),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 12),
                          width: 50,
                          decoration: BoxDecoration(
                            color: isSelected ? selectedColor.withOpacity(0.1) : AppColors.pageBackground,
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? selectedColor : Colors.transparent, width: 2),
                          ),
                          child: Icon(icon, color: isSelected ? selectedColor : AppColors.textGrey, size: 22),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Horizontal Color Picker
                Text('Select Color', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pickerColors.length,
                    itemBuilder: (context, idx) {
                      final color = _pickerColors[idx];
                      final isSelected = selectedColor.value == color.value;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedColor = color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 12),
                          width: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3),
                            boxShadow: isSelected
                                ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)]
                                : [],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Action Button (Save)
                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [selectedColor, selectedColor.withOpacity(0.8)],
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) return;
                      final category = CategoryModel(
                        id: isEditing ? existingCategory.id : '',
                        name: nameController.text.trim(),
                        iconCode: selectedIcon.codePoint,
                        colorValue: selectedColor.value,
                        type: selectedType,
                        userId: '',
                      );

                      if (isEditing) {
                        await _categoryService.updateCategory(category);
                      } else {
                        await _categoryService.addCategory(category);
                      }

                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      isEditing ? 'Update Category' : 'Create Category',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteCategory(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.cardWhite,
        title: Text('Delete Category?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textBlack)),
        content: Text('Are you sure you want to delete "${category.name}"? This action cannot be undone.', style: GoogleFonts.outfit(color: AppColors.textGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textGrey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _categoryService.deleteCategory(category.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: StreamBuilder<List<CategoryModel>>(
        stream: _categoryService.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
          }

          final categories = snapshot.data ?? [];
          final expenses = categories.where((c) => c.type == 'expense').toList();
          final incomes = categories.where((c) => c.type == 'income').toList();

          return Column(
            children: [
              // Premium Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryGreen, Color(0xFF2D6A4F)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                        ),
                        Text(
                          'Category Manager',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: () => _showAddEditCategoryModal(),
                          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Tab Bar
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: AppColors.primaryGreen,
                        unselectedLabelColor: Colors.white,
                        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                        tabs: const [
                          Tab(text: 'Expenses'),
                          Tab(text: 'Incomes'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tab View Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCategoryList(expenses),
                    _buildCategoryList(incomes),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryList(List<CategoryModel> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_rounded, size: 64, color: AppColors.textGrey.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('No categories found', style: GoogleFonts.outfit(color: AppColors.textGrey, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final cat = list[idx];
        final catColor = Color(cat.colorValue);
        final catIcon = IconData(cat.iconCode, fontFamily: 'MaterialIcons');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(catIcon, color: catColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  cat.name,
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textBlack),
                ),
              ),
              // Actions: Edit & Delete
              IconButton(
                onPressed: () => _showAddEditCategoryModal(cat),
                icon: Icon(Icons.edit_rounded, color: Colors.blue.shade400, size: 20),
              ),
              IconButton(
                onPressed: () => _confirmDeleteCategory(cat),
                icon: Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }
}
