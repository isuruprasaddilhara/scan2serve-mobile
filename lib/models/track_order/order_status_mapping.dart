String _normStatus(String? status) => (status ?? '').trim().toLowerCase();

/// Maps Django [Order.status] to the 4-step customer timeline index:
/// 0 Order Sent, 1 Accepted, 2 Cooking, 3 Ready.
///
/// Backend `pending` means the venue has the order (queue / accepted); we treat
/// **Order Sent** and **Accepted** as done and highlight **Accepted** so it matches
/// [trackOrderStatusHeadline] (we do **not** show the word "Pending" there — that
/// confused users vs this step).
/// `preparing` → Cooking. `served` (and later stages) → Ready.
int trackActiveStepIndexFromApiStatus(String status) {
  switch (_normStatus(status)) {
    case 'pending':
      return 1;
    case 'preparing':
      return 2;
    case 'served':
    case 'requested':
    case 'completed':
    case 'ready':
      return 3;
    default:
      return 0;
  }
}

/// Status line under the dish title — aligned with [trackActiveStepIndexFromApiStatus],
/// not a raw copy of the API token (e.g. `pending` ≠ English "waiting").
String trackOrderStatusHeadline(String? status) {
  switch (_normStatus(status)) {
    case 'pending':
      return 'Status: Accepted';
    case 'preparing':
      return 'Status: Preparing';
    case 'served':
    case 'requested':
    case 'completed':
    case 'ready':
      return 'Status: Ready to collect';
    case 'cancelled':
      return 'Status: Cancelled';
    case '':
      return 'Status: In progress';
    default:
      final String raw = (status ?? '').trim();
      if (raw.isEmpty) return 'Status: In progress';
      final String titled =
          raw[0].toUpperCase() + raw.substring(1).replaceAll('_', ' ');
      return 'Status: $titled';
  }
}

bool isOrderReadyFromApiStatus(String? status) {
  switch (_normStatus(status)) {
    case 'served':
    case 'requested':
    case 'completed':
    case 'ready':
      return true;
    default:
      return false;
  }
}

bool canCancelOrderFromApiStatus(String? status) {
  if (status == null || status.trim().isEmpty) return true;
  return _normStatus(status) == 'pending';
}

/// Live polling can stop once the order is finished or cancelled.
bool isTerminalTrackPollingStatus(String? status) {
  return isOrderReadyFromApiStatus(status) || _normStatus(status) == 'cancelled';
}
