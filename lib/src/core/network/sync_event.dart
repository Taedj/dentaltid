enum SyncAction { create, update, delete }

class SyncEvent {
  final String table;
  final SyncAction action;
  final Map<String, dynamic> data;

  SyncEvent({required this.table, required this.action, required this.data});

  Map<String, dynamic> toJson() {
    return {
      'table': table,
      'action': action.toString().split('.').last,
      'data': data,
    };
  }

  factory SyncEvent.fromJson(Map<String, dynamic> json) {
    return SyncEvent(
      table: json['table'],
      action: SyncAction.values.firstWhere((e) => e.toString().split('.').last == json['action']),
      data: json['data'],
    );
  }
}
