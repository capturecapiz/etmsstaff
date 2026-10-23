import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/travel_order.dart';
import '../services/session.dart';
import '../services/edmate_service.dart';
import '../services/api_client.dart';
import '../widgets/status_pill.dart';
import '../widgets/empty_state.dart';

class TravelOrderScreen extends StatefulWidget {
  const TravelOrderScreen({super.key});

  @override
  State<TravelOrderScreen> createState() => _TravelOrderScreenState();
}

class _TravelOrderScreenState extends State<TravelOrderScreen> {
  List<TravelOrder> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = context.read<Session>();
      final orders = await EdmateService(session.api).travelOrders();
      if (mounted) setState(() => _orders = orders);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd();
    return Scaffold(
      appBar: AppBar(title: const Text('Travel Order')),
      // View-only, matching my-travel-order.php: Admin creates and prints
      // Travel Orders (see manage-travel-order.php) — staff see their own
      // here but don't request one from this app, same as the web portal.
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _orders.isEmpty
                      ? const EmptyState(icon: Icons.card_travel_outlined, message: 'No travel orders yet.')
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _orders.length,
                          itemBuilder: (context, i) {
                            final o = _orders[i];
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6).withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.card_travel_outlined, size: 18, color: Color(0xFF3B82F6)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(o.destination,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                                              ),
                                              const SizedBox(width: 8),
                                              StatusPill(label: o.status, color: statusColorFor(o.status)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(o.purpose, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                                          if (o.dateFrom != null && o.dateTo != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 6),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.date_range_outlined, size: 13, color: Colors.grey[500]),
                                                  const SizedBox(width: 4),
                                                  Text('${df.format(o.dateFrom!)} - ${df.format(o.dateTo!)}',
                                                      style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
