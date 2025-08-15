\
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'models.dart';

void main() {
  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'InstaGo Prototype',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class AppState extends ChangeNotifier {
  // data
  List<Branch> branches = [];
  List<Category> categories = [];
  List<Product> products = [];
  String currentBranchId = 'branch_main';

  // per-category UI state
  final Map<String, String> selectedSubcat = {}; // categoryId -> subcatId
  final Map<String, String> layoutPerCategory = {}; // categoryId -> list|grid|carousel

  // anchors
  final Map<String, GlobalKey> sectionKeys = {};

  bool loading = true;
  String? error;

  Future<void> load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/catalog.json');
      final j = json.decode(raw);
      branches = (j['branches'] as List).map((e)=>Branch.fromJson(e)).toList();
      categories = (j['categories'] as List).map((e)=>Category.fromJson(e)).toList();
      products = (j['products'] as List).map((e)=>Product.fromJson(e)).toList();
      for (final c in categories) {
        sectionKeys[c.id] = GlobalKey();
        // default subcat is 'sub-all' if present
        final all = c.subcategories.isNotEmpty ? c.subcategories.first.id : '';
        selectedSubcat[c.id] = all;
        layoutPerCategory[c.id] = 'list';
      }
      loading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
    }
  }

  void setSubcat(String categoryId, String subId) {
    selectedSubcat[categoryId] = subId;
    notifyListeners();
  }

  void setLayout(String categoryId, String layout) {
    layoutPerCategory[categoryId] = layout;
    notifyListeners();
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final state = context.read<AppState>();
      await state.load();
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag, size: 72, color: cs.primary),
            const SizedBox(height: 12),
            const Text('InstaGo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;

    if (app.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (app.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load data'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () { app.loading = true; app.error = null; app.load(); },
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      // Top AppBar (always visible)
      appBar: AppBar(
        toolbarHeight: 64,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(onPressed: (){}, icon: const Icon(Icons.notifications_outlined)),
            Row(children: const [
              Icon(Icons.shopping_bag_outlined),
              SizedBox(width: 8),
              Text('InstaGo', style: TextStyle(fontWeight: FontWeight.w600)),
            ]),
            Row(children: const [
              Icon(Icons.store_mall_directory_outlined),
              SizedBox(width: 4),
              Text('Main Branch'),
            ]),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Account'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), label: 'Cart'),
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        ],
        selectedIndex: 2,
        onDestinationSelected: (_){},
      ),
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          // Top Capsule Box (80% width, centered, rounded bottom only)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Center(
                child: ClipPath(
                  clipper: _BottomRoundedClipper(radius: 24),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 64,
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0,2))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.flag_outlined),
                        SizedBox(width: 24),
                        Icon(Icons.language_outlined),
                        SizedBox(width: 24),
                        Icon(Icons.brightness_6_outlined),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Store cover (generic)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16/7,
                  child: Image.network(
                    'https://picsum.photos/seed/storecover/1200/600',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                readOnly: true, // prototype only
              ),
            ),
          ),
          // Sticky categories bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
              minExtent: 72,
              maxExtent: 72,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _CategoriesBar(onTapCategory: (catId){
                  final key = app.sectionKeys[catId];
                  if (key?.currentContext != null) {
                    Scrollable.ensureVisible(
                      key!.currentContext!,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      alignment: 0.05,
                    );
                  }
                }),
              ),
            ),
          ),
          // All category sections
          for (final cat in app.categories) ...[
            SliverToBoxAdapter(
              child: _CategorySection(category: cat, key: app.sectionKeys[cat.id]),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minExtent;
  final double maxExtent;
  final Widget child;
  _StickyHeaderDelegate({required this.minExtent, required this.maxExtent, required this.child});
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) => false;
}

class _BottomRoundedClipper extends CustomClipper<Path> {
  final double radius;
  _BottomRoundedClipper({required this.radius});
  @override
  Path getClip(Size size) {
    final r = radius;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - r);
    path.quadraticBezierTo(size.width, size.height, size.width - r, size.height);
    path.lineTo(r, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - r);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CategoriesBar extends StatelessWidget {
  final void Function(String categoryId) onTapCategory;
  const _CategoriesBar({required this.onTapCategory});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemBuilder: (c, i){
        final cat = app.categories[i];
        return InkWell(
          onTap: ()=>onTapCategory(cat.id),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.network(cat.cover, width: 48, height: 48, fit: BoxFit.cover),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 72,
                child: Text(cat.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        );
      },
      separatorBuilder: (_, __)=> const SizedBox(width: 12),
      itemCount: app.categories.length,
    );
  }
}

class _CategorySection extends StatelessWidget {
  final Category category;
  const _CategorySection({required this.category, super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final subId = app.selectedSubcat[category.id] ?? (category.subcategories.isNotEmpty ? category.subcategories.first.id : '');
    final layout = app.layoutPerCategory[category.id] ?? 'list';
    final products = context.select<AppState, List<Product>>((s){
      return s.products.where((p) => p.categoryId == category.id && (subId == 'sub-all' || p.subcategoryId == subId)).toList();
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16/7,
              child: Image.network(category.cover, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          // Name
          Text(category.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          // Filters row: All Products + subcategories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  selected: subId == 'sub-all',
                  label: const Text('All Products'),
                  onSelected: (_)=> context.read<AppState>().setSubcat(category.id, 'sub-all'),
                ),
                const SizedBox(width: 8),
                for (final sc in category.subcategories.where((s)=>s.id != 'sub-all')) ...[
                  ChoiceChip(
                    selected: subId == sc.id,
                    label: Text(sc.name),
                    onSelected: (_)=> context.read<AppState>().setSubcat(category.id, sc.id),
                  ),
                  const SizedBox(width: 8),
                ]
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Layout switcher
          Row(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'list', label: Text('List'), icon: Icon(Icons.view_agenda_outlined)),
                  ButtonSegment(value: 'grid', label: Text('Grid'), icon: Icon(Icons.grid_view_outlined)),
                  ButtonSegment(value: 'carousel', label: Text('Carousel'), icon: Icon(Icons.view_carousel_outlined)),
                ],
                selected: {layout},
                onSelectionChanged: (s)=> context.read<AppState>().setLayout(category.id, s.first),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Products area
          if (layout == 'list') ...[
            for (final p in products) _ProductListTile(p: p),
          ] else if (layout == 'grid') ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 3/4,
              ),
              itemBuilder: (_, i)=> _ProductCard(p: products[i]),
            ),
          ] else ...[
            SizedBox(
              height: 240,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, i)=> SizedBox(width: 200, child: _ProductCard(p: products[i])),
                separatorBuilder: (_, __)=> const SizedBox(width: 12),
                itemCount: products.length,
              ),
            )
          ]
        ],
      ),
    );
  }
}

class _ProductListTile extends StatelessWidget {
  final Product p;
  const _ProductListTile({required this.p});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(p.image, width: 72, height: 72, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(p.unit, style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.star, size: 16, color: Colors.amber[700]),
                    const SizedBox(width: 4),
                    Text(p.rating.toStringAsFixed(1)),
                    const SizedBox(width: 8),
                    Text('(${p.reviews})', style: TextStyle(color: cs.onSurfaceVariant)),
                  ]),
                ],
              ),
            ),
            Text('\$${p.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            FilledButton(onPressed: (){}, child: const Text('Add')),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product p;
  const _ProductCard({required this.p});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              child: Image.network(p.image, width: double.infinity, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(p.unit, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('\$${p.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    IconButton(onPressed: (){}, icon: const Icon(Icons.add_shopping_cart_outlined)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
