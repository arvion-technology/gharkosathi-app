import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/repository.dart';
import '../router.dart';
import '../theme/arvion_theme.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final HomeServicesRepository _repository = InMemoryRepository();
  List<Service> _services = const [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final services = await _repository.services();
    if (!mounted) return;
    setState(() {
      _services = services;
      _loading = false;
    });
  }

  List<Service> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _services;
    return _services.where((service) {
      return service.name.toLowerCase().contains(query) || service.category.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('What do you need?'),
        actions: [
          IconButton(
            tooltip: 'Wallet',
            onPressed: () => Navigator.of(context).pushNamed(AppRouter.wallet),
            icon: const Icon(Icons.account_balance_wallet_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ArvionColors.gold))
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Search plumbing, electrical, cleaning',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                ),
                const SizedBox(height: 18),
                if (_filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'No services match that search. Clearing the field shows the full catalogue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ArvionColors.muted),
                    ),
                  )
                else
                  ..._filtered.map(
                    (service) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: CircleAvatar(
                            backgroundColor: ArvionColors.surface2,
                            child: Text(
                              service.name.substring(0, 1),
                              style: const TextStyle(color: ArvionColors.gold, fontWeight: FontWeight.w700),
                            ),
                          ),
                          title: Text(service.name),
                          subtitle: Text(
                            '${service.category} · ${service.durationMinutes} min · from NPR ${service.basePrice}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).pushNamed(
                            AppRouter.booking,
                            arguments: service.id,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Wallet'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
