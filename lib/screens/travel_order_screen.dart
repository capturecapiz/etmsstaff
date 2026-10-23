import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/travel_order.dart';
import '../services/session.dart';
import '../services/edmate_service.dart';
import '../services/api_client.dart';
import '../widgets/status_pill.dart';
import '../widgets/empty_state.dart';
import '../widgets/gradient_header.dart';

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

  void _showOrderDetail(TravelOrder o) {
    final df = DateFormat.yMMMd();
    final natureParts = [
      if (o.natureOfficialTime) 'Official Time',
      if (o.natureOfficialBusiness) 'Official Business',
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(o.destination, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                    StatusPill(label: o.status, color: statusColorFor(o.status)),
                  ],
                ),
                const SizedBox(height: 16),
                _detailRow(Icons.flag_outlined, 'Purpose', o.purpose),
                if (o.dateFrom != null && o.dateTo != null)
                  _detailRow(Icons.date_range_outlined, 'Period', '${df.format(o.dateFrom!)} - ${df.format(o.dateTo!)}'),
                if (natureParts.isNotEmpty)
                  _detailRow(Icons.work_outline_rounded, 'Nature', natureParts.join(' & ')),
                if (o.officerNames.isNotEmpty)
                  _detailRow(Icons.groups_outlined, 'Officers', o.officerNames),
                if (o.recommendingName.isNotEmpty)
                  _detailRow(Icons.how_to_reg_outlined, 'Recommending Approval',
                      '${o.recommendingName}${o.recommendingDesignation.isNotEmpty ? '\n${o.recommendingDesignation}' : ''}'),
                if (o.approvingName.isNotEmpty)
                  _detailRow(Icons.verified_outlined, 'Approved By',
                      '${o.approvingName}${o.approvingDesignation.isNotEmpty ? '\n${o.approvingDesignation}' : ''}'),
                if (o.createdAt != null) _detailRow(Icons.event_available_outlined, 'Created', df.format(o.createdAt!)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd();
    final approvedCount = _orders.where((o) => o.status == 'Approved').length;
    final pendingCount = _orders.where((o) => o.status == 'Pending' || o.status == 'Forwarded').length;
    final disapprovedCount = _orders.where((o) => o.status == 'Disapproved').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      // View-only, matching my-travel-order.php: Admin creates and prints
      // Travel Orders (see manage-travel-order.php) — staff see their own
      // here but don't request one from this app, same as the web portal.
      body: Column(
        children: [
          GradientHeader(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 10),
                    const Text('Travel Order', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 14),
                HeaderStatRow(
                  stats: [
                    HeaderStat(value: '$approvedCount', label: 'Approved'),
                    HeaderStat(value: '$pendingCount', label: 'Pending'),
                    HeaderStat(value: '$disapprovedCount', label: 'Denied'),
                    HeaderStat(value: '${_orders.length}', label: 'Total'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
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
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _showOrderDetail(o),
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
                                          Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Row(
                                              children: [
                                                if (o.dateFrom != null && o.dateTo != null) ...[
                                                  Icon(Icons.date_range_outlined, size: 13, color: Colors.grey[500]),
                                                  const SizedBox(width: 4),
                                                  Text('${df.format(o.dateFrom!)} - ${df.format(o.dateTo!)}',
                                                      style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
                                                ],
                                                const Spacer(),
                                                const Text(
                                                  'View',
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF3B82F6)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ),
                            );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}
