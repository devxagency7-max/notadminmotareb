import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:animations/animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:motareb/core/extensions/loc_extension.dart';

import '../../../core/models/property_model.dart';

import '../../property_details/screens/property_details_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/home_provider.dart';
import 'large_property_card.dart';
import 'property_card.dart';
import '../screens/university_properties_screen.dart';

import 'package:motareb/core/services/ad_service.dart';
import '../../../utils/guest_checker.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Access providers
    final authProvider = context.watch<AuthProvider>();
    final homeProvider = context.watch<HomeProvider>();

    if (homeProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<String> categoriesList = [
      context.loc.all,
      context.loc.university,
      context.loc.youth,
      context.loc.girls,
      context.loc.bed,
      context.loc.room,
    ];

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!homeProvider.isLoadingMore &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
          // Trigger earlier
          context.read<HomeProvider>().loadMoreProperties();
        }
        return true;
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeader(context, authProvider),
                const SizedBox(height: 20),
                _buildSearchBar(context),
                const SizedBox(height: 20),
                _buildCategories(context, categoriesList),
                const SizedBox(height: 20),
              ]),
            ),
          ),
          ..._buildContentSlivers(context, homeProvider),
          if (homeProvider.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }

  List<Widget> _buildContentSlivers(
    BuildContext context,
    HomeProvider homeProvider,
  ) {
    if (homeProvider.error != null) {
      return [
        SliverToBoxAdapter(
          child: Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 10),
                Text('${context.loc.errorOccurred}: ${homeProvider.error}'),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () =>
                      context.read<HomeProvider>().loadMoreProperties(),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (homeProvider.allProperties.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Center(child: Text(context.loc.noPropertiesFound)),
        ),
      ];
    }

    // New: Check for empty search results
    final bool isSearchActive = homeProvider.searchQuery.isNotEmpty;
    final selectedIndex = homeProvider.selectedCategoryIndex;

    bool isEmptySearchResult = false;
    if (isSearchActive) {
      if (selectedIndex == 1 && homeProvider.uniqueUniversities.isEmpty) {
        isEmptySearchResult = true;
      } else if (selectedIndex > 1 && homeProvider.filteredByCategory.isEmpty) {
        isEmptySearchResult = true;
      } else if (selectedIndex == 0 &&
          homeProvider.featuredProperties.isEmpty &&
          homeProvider.recentProperties.isEmpty) {
        isEmptySearchResult = true;
      }
    }

    if (isEmptySearchResult) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  context.loc.noSearchResults,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    // 1. University View
    if (selectedIndex == 1) {
      final universities = homeProvider.uniqueUniversities;

      if (universities.isEmpty) {
        return [
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(context.loc.noUniversitiesFound),
              ),
            ),
          ),
        ];
      }

      return [
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final uni = universities[index];
            final uniProperties = homeProvider.getPropertiesForUniversity(uni);
            if (uniProperties.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  _buildSectionTitle(
                    context,
                    ' $uni',
                    context.loc.viewAll,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UniversityPropertiesScreen(
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
              ),
            );
          }, childCount: universities.length),
        ),
      ];
    }

    // 2. Filtered View (Youth, Girls, Bed, Room)
    if (selectedIndex > 1) {
      final filtered = homeProvider.filteredByCategory;
      return _buildFilteredListSlivers(context, filtered);
    }

    // 0. Default View (All)
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverToBoxAdapter(
          child: Column(
            children: [
              _buildSectionTitle(context, context.loc.featuredForYou, ''),
              const SizedBox(height: 15),
              _buildFeaturedList(context, homeProvider.featuredProperties),
              const SizedBox(height: 25),
              _buildSectionTitle(context, context.loc.recentlyAdded, ''),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: _buildRecentlyAddedSliverList(
          context,
          homeProvider.recentProperties,
        ),
      ),
    ];
  }

  Widget _buildHeader(BuildContext context, AuthProvider authProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
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
                          color: Colors.black.withValues(alpha: 0.1),
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
                  context.loc.goodMorning,
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '${context.loc.welcome} ${authProvider.userData?['name'] ?? context.loc.guest}',
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
        Row(
          children: [
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
                Expanded(
                  child: TextField(
                    textAlign: TextAlign.right,
                    onChanged: (value) {
                      context.read<HomeProvider>().setSearchQuery(value);
                    },
                    decoration: InputDecoration(
                      hintText: context.loc.searchHint,
                      hintStyle: GoogleFonts.cairo(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Search Button with Gradient Design (Moved from inside search bar)
        Container(
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
                color: const Color(0xFF008695).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(Icons.search_rounded, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildCategories(BuildContext context, List<String> categories) {
    return _HomeCategories(categories: categories);
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
          return PropertyCard(property: properties[index]);
        },
      ),
    );
  }

  Widget _buildRecentlyAddedSliverList(
    BuildContext context,
    List<Property> properties,
  ) {
    final totalItems = properties.length + (properties.length ~/ 5);

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if ((index + 1) % 6 == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: AdService().getAdWidget(
              factoryId: 'listTileSmall',
              height: 100,
            ),
          );
        }

        final propertyIndex = index - (index ~/ 6);
        if (propertyIndex >= properties.length) return const SizedBox.shrink();

        final property = properties[propertyIndex];
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: GestureDetector(
            onTap: () {
              if (!GuestChecker.check(context)) return;
            },
            child: AbsorbPointer(
              absorbing: context.watch<AuthProvider>().isGuest,
              child: OpenContainer(
                transitionType: ContainerTransitionType.fade,
                transitionDuration: const Duration(milliseconds: 500),
                closedColor: Theme.of(context).cardTheme.color ?? Colors.white,
                closedElevation: isDark ? 0 : 2,
                openElevation: 0,
                closedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: isDark
                      ? BorderSide(color: Theme.of(context).dividerColor)
                      : BorderSide.none,
                ),
                openBuilder: (context, _) =>
                    PropertyDetailsScreen(property: property),
                closedBuilder: (context, openContainer) {
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: CachedNetworkImage(
                            imageUrl: property.imageUrl,
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 80,
                              width: 80,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 80,
                              width: 80,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.bed, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
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
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    context.loc.newLabel,
                                    style: GoogleFonts.cairo(
                                      color: Colors.green,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              Text(
                                property.localizedTitle(context),
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                              Text(
                                property.localizedLocation(context),
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                          ).createShader(bounds),
                          child: Text(
                            '${NumberFormat.decimalPattern().format(property.price)} ${context.loc.currency}',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      }, childCount: totalItems),
    );
  }

  List<Widget> _buildFilteredListSlivers(
    BuildContext context,
    List<Property> properties,
  ) {
    if (properties.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(context.loc.noCategoryProperties),
            ),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: LargePropertyCard(property: properties[index]),
            );
          }, childCount: properties.length),
        ),
      ),
    ];
  }
}

class _HomeCategories extends StatefulWidget {
  final List<String> categories;
  const _HomeCategories({required this.categories});

  @override
  State<_HomeCategories> createState() => _HomeCategoriesState();
}

class _HomeCategoriesState extends State<_HomeCategories> {
  final ScrollController _scrollController = ScrollController();
  bool _showArrow = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScroll());
  }

  void _checkScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final show = maxScroll > 0 && currentScroll < maxScroll - 10;
    if (show != _showArrow) {
      if (mounted) setState(() => _showArrow = show);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: widget.categories.length,
            padding: EdgeInsets.only(left: _showArrow ? 30 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final selectedCategoryIndex = context
                  .watch<HomeProvider>()
                  .selectedCategoryIndex;
              final isSelected = index == selectedCategoryIndex;
              return GestureDetector(
                onTap: () =>
                    context.read<HomeProvider>().setCategoryIndex(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                          )
                        : null,
                    color: isSelected
                        ? null
                        : Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? null
                        : Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).dividerColor
                                : Colors.grey.shade200,
                          ),
                  ),
                  child: Text(
                    widget.categories[index],
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
          if (_showArrow)
            Positioned(
              left: -5,
              child: IgnorePointer(
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor,
                        Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: Color(0xFF008695),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
