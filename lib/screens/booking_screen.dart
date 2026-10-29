import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/repository.dart';
import '../router.dart';
import '../theme/arvion_theme.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.serviceId});

  final String serviceId;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final HomeServicesRepository _repository = InMemoryRepository();
  final TextEditingController _address = TextEditingController(text: 'Baneshwor, Kathmandu');
  Quote? _quote;
  int _slot = 0;
  bool _submitting = false;

  static const _slots = ['Today, 2-4 PM', 'Tomorrow, 9-11 AM', 'Saturday, 10-12'];

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    final quote = await _repository.quoteFor(widget.serviceId);
    if (!mounted) return;
    setState(() => _quote = quote);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final job = await _repository.requestJob(
      serviceId: widget.serviceId,
      address: _address.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).pushReplacementNamed(AppRouter.tracking, arguments: job);
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quote = _quote;
    return Scaffold(
      appBar: AppBar(title: const Text('Book a visit')),
      body: quote == null
          ? const Center(child: CircularProgressIndicator(color: ArvionColors.gold))
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                const Text('Address', style: TextStyle(fontSize: 12, color: ArvionColors.muted)),
                const SizedBox(height: 6),
                TextField(controller: _address),
                const SizedBox(height: 20),
                const Text('Time window', style: TextStyle(fontSize: 12, color: ArvionColors.muted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var index = 0; index < _slots.length; index++)
                      ChoiceChip(
                        label: Text(_slots[index]),
                        selected: _slot == index,
                        selectedColor: const Color(0x33F5C26B),
                        onSelected: (_) => setState(() => _slot = index),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _priceRow('Service', 'NPR ${quote.amount}'),
                        const SizedBox(height: 8),
                        _priceRow('Visit fee', 'NPR ${quote.visitFee}'),
                        const Divider(height: 22),
                        _priceRow('Total held in escrow', quote.formatted, strong: true),
                        const SizedBox(height: 8),
                        const Text(
                          'The worker is paid after you confirm the job is complete.',
                          style: TextStyle(fontSize: 12, color: ArvionColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(_submitting ? 'Requesting…' : 'Request worker'),
                ),
              ],
            ),
    );
  }

  Widget _priceRow(String label, String value, {bool strong = false}) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: strong ? ArvionColors.text : ArvionColors.muted)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            color: strong ? ArvionColors.gold : ArvionColors.text2,
          ),
        ),
      ],
    );
  }
}
