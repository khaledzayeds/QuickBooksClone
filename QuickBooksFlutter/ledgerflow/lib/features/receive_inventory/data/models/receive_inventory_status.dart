enum ReceiveInventorySaveMode {
  draft(1, 'Draft'),
  saveAndPost(2, 'SaveAndPost');

  const ReceiveInventorySaveMode(this.value, this.label);

  final int value;
  final String label;
}
