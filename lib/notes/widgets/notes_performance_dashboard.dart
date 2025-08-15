import 'package:flutter/material.dart';
import '../services/notes_telemetry.dart';
import '../config/notes_config.dart';

/// Widget for displaying notes performance metrics and health status
class NotesPerformanceDashboard extends StatefulWidget {
  const NotesPerformanceDashboard({super.key});

  @override
  State<NotesPerformanceDashboard> createState() =>
      _NotesPerformanceDashboardState();
}

class _NotesPerformanceDashboardState extends State<NotesPerformanceDashboard> {
  Map<String, dynamic> _aggregatedMetrics = {};
  bool _isHealthy = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
  }

  void _loadPerformanceData() {
    setState(() {
      _isLoading = true;
    });

    try {
      _aggregatedMetrics = NotesTelemetry.instance.getAggregatedMetrics();
      _isHealthy = NotesTelemetry.instance.isPerformanceHealthy();
    } catch (e) {
      debugPrint('Error loading performance data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearMetrics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('נקה מדדי ביצועים'),
        content: const Text('האם אתה בטוח שברצונך לנקות את כל מדדי הביצועים?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () {
              NotesTelemetry.instance.clearMetrics();
              Navigator.of(context).pop();
              _loadPerformanceData();
            },
            child: const Text('נקה'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!NotesConfig.telemetryEnabled || !NotesEnvironment.telemetryEnabled) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.analytics_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'מדדי ביצועים מבוטלים',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'הפעל telemetry כדי לראות מדדי ביצועים',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isHealthy ? Icons.health_and_safety : Icons.warning,
                  color: _isHealthy ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'מדדי ביצועים',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadPerformanceData,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'רענן נתונים',
                ),
                IconButton(
                  onPressed: _clearMetrics,
                  icon: const Icon(Icons.clear_all),
                  tooltip: 'נקה מדדים',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              _buildHealthStatus(),
              const SizedBox(height: 16),
              _buildAnchoringMetrics(),
              const SizedBox(height: 16),
              _buildSearchMetrics(),
              const SizedBox(height: 16),
              _buildBatchMetrics(),
              const SizedBox(height: 16),
              _buildStrategyMetrics(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isHealthy
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isHealthy ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isHealthy ? Icons.check_circle : Icons.warning,
            color: _isHealthy ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Text(
            _isHealthy ? 'ביצועים תקינים' : 'ביצועים דורשים תשומת לב',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isHealthy ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnchoringMetrics() {
    final anchoring =
        _aggregatedMetrics['anchoring_performance'] as Map<String, dynamic>? ??
            {};

    return _buildMetricSection(
      'עיגון הערות',
      Icons.anchor,
      [
        _buildMetricRow(
            'עוגן בהצלחה', '${anchoring['anchored_avg_ms'] ?? 0}ms'),
        _buildMetricRow('הוזז', '${anchoring['shifted_avg_ms'] ?? 0}ms'),
        _buildMetricRow('יתום', '${anchoring['orphan_avg_ms'] ?? 0}ms'),
      ],
    );
  }

  Widget _buildSearchMetrics() {
    final search =
        _aggregatedMetrics['search_performance'] as Map<String, dynamic>? ?? {};

    return _buildMetricSection(
      'חיפוש',
      Icons.search,
      [
        _buildMetricRow('זמן ממוצע', '${search['avg_ms'] ?? 0}ms'),
        _buildMetricRow('P95', '${search['p95_ms'] ?? 0}ms'),
        _buildMetricRow('תוצאות ממוצעות', '${search['avg_results'] ?? 0}'),
      ],
    );
  }

  Widget _buildBatchMetrics() {
    final batch =
        _aggregatedMetrics['batch_performance'] as Map<String, dynamic>? ?? {};

    return _buildMetricSection(
      'עיבוד אצווה',
      Icons.batch_prediction,
      [
        _buildMetricRow('זמן ממוצע', '${batch['avg_ms'] ?? 0}ms'),
        _buildMetricRow('שיעור הצלחה', '${batch['success_rate'] ?? 0}%'),
      ],
    );
  }

  Widget _buildStrategyMetrics() {
    final strategy =
        _aggregatedMetrics['strategy_usage'] as Map<String, dynamic>? ?? {};

    return _buildMetricSection(
      'אסטרטגיות עיגון',
      Icons.psychology,
      [
        _buildMetricRow('התאמה מדויקת', '${strategy['exact_avg_ms'] ?? 0}ms'),
        _buildMetricRow('התאמה בהקשר', '${strategy['context_avg_ms'] ?? 0}ms'),
        _buildMetricRow('התאמה מטושטשת', '${strategy['fuzzy_avg_ms'] ?? 0}ms'),
      ],
    );
  }

  Widget _buildMetricSection(
      String title, IconData icon, List<Widget> metrics) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...metrics,
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Compact version of performance dashboard for sidebar
class CompactPerformanceDashboard extends StatelessWidget {
  const CompactPerformanceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!NotesConfig.telemetryEnabled || !NotesEnvironment.telemetryEnabled) {
      return const SizedBox.shrink();
    }

    final isHealthy = NotesTelemetry.instance.isPerformanceHealthy();
    final aggregated = NotesTelemetry.instance.getAggregatedMetrics();
    final anchoring =
        aggregated['anchoring_performance'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isHealthy
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHealthy ? Icons.check_circle_outline : Icons.warning_outlined,
            size: 16,
            color: isHealthy ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            '${anchoring['anchored_avg_ms'] ?? 0}ms',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
