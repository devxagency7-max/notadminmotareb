import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

// import '../../../admin/admin_dashboard.dart'; // Removed
import '../../../core/models/property_model.dart';
import '../../../screens/filter_screen.dart';
import '../../../screens/property_details_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/home_provider.dart';
import 'large_property_card.dart'; // Import LargePropertyCard
import 'property_card.dart';
import '../screens/university_properties_screen.dart';
import 'native_ad_widget.dart';

class HomeContent extends StatelessWidget {
  HomeContent({super.key});

  final List<String> _categories = [
    'الكل',
    'جامعة',
    'شباب',
    'بنات',
    'سرير ',
    'غرفة',
  ];

  // Dummy Data

  @override
  Widget build(BuildContext context) {
    // Access providers
    final authProvider = context.watch<AuthProvider>();

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      child: Column(
        children: [
          _buildHeader(context, authProvider),
          const SizedBox(height: 20),
          _buildSearchBar(context),
          const SizedBox(height: 20),
          _buildCategories(context),
          const SizedBox(height: 20),
          StreamBuilder<List<Property>>(
            stream: context.read<HomeProvider>().propertiesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('حدث خطأ: ${snapshot.error}'));
              }

              final properties = snapshot.data ?? [];
              if (properties.isEmpty) {
                return const Center(
                  child: Text('لا توجد عقارات مضافة حتى الآن'),
                );
              }

              // Check selected category
              final selectedCategoryIndex = context
                  .watch<HomeProvider>()
                  .selectedCategoryIndex;

              // If "University" category is selected (Index 1)
              if (selectedCategoryIndex == 1) {
                // Collect all unique universities from properties
                final Set<String> allUniversities = {};
                for (var p in properties) {
                  allUniversities.addAll(p.universities);
                }

                if (allUniversities.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('لا توجد جامعات مرتبطة بالعقارات المتاحة'),
                    ),
                  );
                }

                final sortedUniversities = allUniversities.toList()..sort();

                return Column(
                  children: sortedUniversities.map((uni) {
                    final uniProperties = properties
                        .where((p) => p.universities.contains(uni))
                        .toList();

                    if (uniProperties.isEmpty) return const SizedBox.shrink();

                    return Column(
                      children: [
                        _buildSectionTitle(
                          context,
                          ' ${uni}',
                          'عرض الكل',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UniversityPropertiesScreen(
                                      universityName: uni,
                                      properties: uniProperties,
                                    ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 15),
                        _buildFeaturedList(context, uniProperties),
                        const SizedBox(height: 25),
                      ],
                    );
                  }).toList(),
                );
              }

              // Filtering Logic for other categories
              // Index 2: Youth (Male)
              if (selectedCategoryIndex == 2) {
                final filtered = properties
                    .where(
                      (p) =>
                          p.gender == 'male' ||
                          p.tags.contains('شباب') ||
                          p.tags.contains('ذكور'),
                    )
                    .toList();
                return _buildFilteredList(context, filtered);
              }
              // Index 3: Girls (Female)
              if (selectedCategoryIndex == 3) {
                final filtered = properties
                    .where(
                      (p) =>
                          p.gender == 'female' ||
                          p.tags.contains('بنات') ||
                          p.tags.contains('إناث'),
                    )
                    .toList();
                return _buildFilteredList(context, filtered);
              }
              // Index 4: Bed
              if (selectedCategoryIndex == 4) {
                final filtered = properties
                    .where((p) => p.type == 'سرير' || p.type.contains('سرير'))
                    .toList();
                return _buildFilteredList(context, filtered);
              }
              // Index 5: Room
              if (selectedCategoryIndex == 5) {
                final filtered = properties
                    .where((p) => p.type == 'غرفة' || p.type.contains('غرفة'))
                    .toList();
                return _buildFilteredList(context, filtered);
              }

              // Default View (All, or other categories if not handled specifically)
              // For other categories (Youth, Girls, Bed), you might want to filter too,
              // but the requirement specifically requested grouping for "University".
              // For now, we apply basic filtering if needed, or just show default "Featured + Recent".

              // Note: If you want to filter by "Youth" (Index 2), "Girls" (Index 3), etc.
              // you should add that logic here or in the provider query.
              // Assuming for now standard behavior for others as per current code.

              final featuredProperties = properties
                  .where((p) => p.rating >= 4.5)
                  .toList();

              final displayFeatured = featuredProperties.isNotEmpty
                  ? featuredProperties
                  : properties.take(5).toList();

              return Column(
                children: [
                  _buildSectionTitle(context, 'مميزة لك ✨', 'عرض الكل'),
                  const SizedBox(height: 15),
                  _buildFeaturedList(context, displayFeatured),
                  const SizedBox(height: 25),
                  _buildSectionTitle(context, 'أضيف حديثاً 🆕', ''),
                  const SizedBox(height: 15),
                  _buildRecentlyAddedList(context, properties),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider authProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Greeting
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).cardTheme.color ?? Colors.white,
                  width: 2,
                ),
                boxShadow: Theme.of(context).brightness == Brightness.dark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: authProvider.userData?['photoUrl'] != null
                    ? CachedNetworkImage(
                        imageUrl: authProvider.userData!['photoUrl'],
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 44,
                          height: 44,
                          color: Colors.grey[200],
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 44,
                          height: 44,
                          color: Colors.grey[100],
                          child: const Icon(Icons.person, color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: 44,
                        height: 44,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[900]
                            : Colors.grey[100],
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'صباح الخير',
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'أهلاً ${authProvider.userData?['name'] ?? 'زائر'}',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ],
        ),
        // Actions Row
        Row(
          children: [
            // Admin Button Removed
            // Notification
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                shape: BoxShape.circle,
                boxShadow: Theme.of(context).brightness == Brightness.dark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: Icon(
                Icons.notifications_outlined,
                size: 22,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(15),
              boxShadow: Theme.of(context).brightness == Brightness.dark
                  ? []
                  : const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
              border: Theme.of(context).brightness == Brightness.dark
                  ? Border.all(color: Theme.of(context).dividerColor)
                  : null,
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText:"حابب تسكن فين..؟",
                      hintStyle: GoogleFonts.cairo(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (value) {
                      // Switch to search tab on submit
                      context.read<HomeProvider>().setIndex(1);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => FilterScreen()),
            );
          },
          child: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF008695).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(Icons.tune, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildCategories(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selectedIndex = context
              .watch<HomeProvider>()
              .selectedCategoryIndex;
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => context.read<HomeProvider>().setCategoryIndex(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      )
                    : null,
                color: isSelected ? null : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).dividerColor
                            : Colors.grey.shade200,
                      ),
              ),
              child: Text(
                _categories[index],
                style: GoogleFonts.cairo(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    String action, {
    VoidCallback? onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (action.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                action,
                style: GoogleFonts.cairo(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturedList(BuildContext context, List<Property> properties) {
    return SizedBox(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: properties.length,
        separatorBuilder: (_, __) => const SizedBox(width: 15),
        itemBuilder: (context, index) {
          // Use PropertyCard for cleaner code
          return PropertyCard(property: properties[index]);
        },
      ),
    );
  }

  Widget _buildRecentlyAddedList(
    BuildContext context,
    List<Property> properties,
  ) {
    // Ad every 5 items
    final totalItems = properties.length + (properties.length ~/ 5);

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: totalItems,
      separatorBuilder: (_, __) => const SizedBox(height: 15),
      itemBuilder: (context, index) {
        // Ad position: Every 6th slot (index 5, 11, etc.)
        if ((index + 1) % 6 == 0) {
          return const NativeAdWidget(height: 100, factoryId: 'listTileSmall');
        }

        // Calculate actual property index
        final propertyIndex = index - (index ~/ 6);
        if (propertyIndex >= properties.length) return const SizedBox.shrink();

        final property = properties[propertyIndex];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PropertyDetailsScreen(property: property),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Theme.of(context).brightness == Brightness.dark
                  ? Border.all(color: Theme.of(context).dividerColor)
                  : null,
              boxShadow: Theme.of(context).brightness == Brightness.dark
                  ? []
                  : const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    property.imageUrl,
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 80,
                      width: 80,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.bed, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (property.isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'جديد',
                            style: GoogleFonts.cairo(
                              color: Colors.green,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      Text(
                        property.title,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${property.location} ${property.tags.isNotEmpty ? "• ${property.tags.first}" : ""}',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            property.rating.toString(),
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  property.price,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF008695),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilteredList(BuildContext context, List<Property> properties) {
    if (properties.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('لا توجد عقارات متاحة في هذا التصنيف حالياً'),
        ),
      );
    }
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: properties.length,
      itemBuilder: (context, index) {
        return LargePropertyCard(property: properties[index]);
      },
    );
  }
}
