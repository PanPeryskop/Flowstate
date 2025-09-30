import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flowstate/models/coffee.dart';
import 'package:flowstate/services/database_service.dart';
import 'package:flowstate/screens/coffee/coffee_detail_screen.dart';
import 'package:flowstate/screens/coffee_form/coffee_form_screen.dart';
import 'package:flowstate/screens/home/coffee_card.dart';
import 'package:flowstate/theme/flowstate_theme.dart';
import 'package:flowstate/widgets/animated_wave.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  late Future<List<Coffee>> _coffeesFuture;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _showScrollToTop = _scrollController.offset > 300;
      });
    });
    _loadCoffees();
  }

  void _loadCoffees() {
    _coffeesFuture = context.read<DatabaseService>().getAllCoffees();
  }

  Future<void> _refreshCoffees() async {
    setState(() {
      _loadCoffees();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                pinned: true,
                backgroundColor: FlowstateTheme.primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Flowstate',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 26,
                          color: Colors.white,
                        ),
                  ),
                  centerTitle: true,
                  background: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              FlowstateTheme.primaryColor,
                              FlowstateTheme.accentColor,
                            ],
                          ),
                        ),
                      ),
                      const Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: AnimatedWave(
                          height: 70,
                          speed: 0.7,
                        ),
                      ),
                      const Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: AnimatedWave(
                          height: 40,
                          speed: 1.2,
                          offset: 3.14 / 2,
                          opacity: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: FutureBuilder<List<Coffee>>(
                  future: _coffeesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else if (snapshot.hasError) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 60,
                                color: Colors.red.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading coffees',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${snapshot.error}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.coffee,
                                  size: 80,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'No coffees yet',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        color: Colors.grey.shade700,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Add your first coffee to start brewing!',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 32),
                                Align(
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: 220,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const CoffeeFormScreen(),
                                          ),
                                        ).then((_) => _refreshCoffees());
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add Coffee'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else {
                      final coffees = snapshot.data!;
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final coffee = coffees[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: CoffeeCard(
                                coffee: coffee,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CoffeeDetailScreen(
                                        coffee: coffee,
                                      ),
                                    ),
                                  ).then((_) => _refreshCoffees());
                                },
                              ),
                            );
                          },
                          childCount: coffees.length,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          if (_showScrollToTop)
            Positioned(
              bottom: 100,
              right: 20,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                onPressed: _scrollToTop,
                child: Icon(
                  Icons.arrow_upward,
                  color: FlowstateTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CoffeeFormScreen(),
            ),
          ).then((_) => _refreshCoffees());
        },
        label: const Text('Add Coffee'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}