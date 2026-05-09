import sys

file_path = r"e:\P\QuickBooksClone\QuickBooksFlutter\ledgerflow\lib\features\sales_receipts\screens\sales_receipt_form_page.dart"
with open(file_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

new_content = """    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Ribbon Area (Top Bar)
          _buildRibbon(),
          
          // 2. Dark Blue Bar
          _buildBlueBar(customers, depositAccounts),
          
          // 3. Main Content Area (Form + Right Sidebar)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Side (Main Form)
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Form Header (Title + Fields)
                      _buildFormHeader(),
                      
                      // Grid (Table)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: TransactionLineTable(
                              lines: _lines,
                              priceMode: TransactionLinePriceMode.sales,
                              onChanged: _onTableChanged,
                              onAddLine: _addLine,
                              onClearLines: _clearLines,
                              showAccountColumn: false,
                            ),
                          ),
                        ),
                      ),
                      
                      // Footer
                      _buildFooter(),
                    ],
                  ),
                ),
                
                // Right Sidebar
                _buildRightSidebar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedDot() {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.only(left: 4, bottom: 4),
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildRibbon() {
    return Container(
      color: const Color(0xFFF0F0F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ribbon Tabs
          Container(
            color: const Color(0xFFE5E5E5),
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                _buildRibbonTab('Main', isActive: true),
                _buildRibbonTab('Formatting', hasRedDot: true),
                _buildRibbonTab('Reports', hasRedDot: true),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.black54),
                  onPressed: _cancel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          // Ribbon Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFCCCCCC))),
            ),
            child: Row(
              children: [
                _buildRibbonButton(Icons.note_add, 'New', onPressed: () => _save(closeAfterSave: false)),
                _buildRibbonButton(Icons.save, 'Save', onPressed: () => _save(closeAfterSave: true)),
                _buildRibbonButton(Icons.delete_forever, 'Delete', hasRedDot: true),
                _buildRibbonButton(Icons.copy, 'Create a Copy', hasRedDot: true),
                const SizedBox(width: 16),
                _buildRibbonButton(Icons.print, 'Print', hasRedDot: true),
                _buildRibbonButton(Icons.email, 'Email', hasRedDot: true),
                const SizedBox(width: 16),
                _buildRibbonButton(Icons.attach_file, 'Attach\\nFile', hasRedDot: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRibbonTab(String text, {bool isActive = false, bool hasRedDot = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF0F0F0) : Colors.transparent,
        border: isActive
            ? const Border(
                top: BorderSide(color: Color(0xFFCCCCCC)),
                left: BorderSide(color: Color(0xFFCCCCCC)),
                right: BorderSide(color: Color(0xFFCCCCCC)),
              )
            : null,
      ),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.black : Colors.black87,
            ),
          ),
          if (hasRedDot) _buildRedDot(),
        ],
      ),
    );
  }

  Widget _buildRibbonButton(IconData icon, String label, {bool isBlue = false, VoidCallback? onPressed, bool hasRedDot = false}) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: isBlue ? Colors.blue.shade700 : Colors.blue.shade600),
                if (hasRedDot) _buildRedDot(),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlueBar(List<CustomerModel> customers, List<AccountModel> depositAccounts) {
    return Container(
      color: const Color(0xFF5B7B9E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Text('CUSTOMER', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          SizedBox(
            width: 250,
            height: 32,
            child: Material(
              color: Colors.white,
              child: _CustomerTypeAheadField(
                controller: _customerCtrl,
                customers: customers,
                label: '',
                selectedCustomer: _selectedCustomer,
                onSelected: _selectCustomerDirect,
                onClear: _clearCustomer,
                onDetails: _showCustomerContextDialog,
              ),
            ),
          ),
          const SizedBox(width: 24),
          const Text('DEPOSIT TO', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          SizedBox(
            width: 250,
            height: 32,
            child: Material(
              color: Colors.white,
              child: _DepositAccountTypeAheadField(
                controller: _depositAccountCtrl,
                accounts: depositAccounts,
                selectedAccount: _selectedDepositAccount,
                onSelected: _selectDepositAccountDirect,
                onClear: _clearDepositAccount,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Row(
            children: [
              const Text('TEMPLATE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              _buildRedDot(),
            ],
          ),
          const SizedBox(width: 8),
          Container(
            width: 150,
            height: 28,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: const Text('Custom Sales...', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildFormHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title
          const Text(
            'Sales Receipt',
            style: TextStyle(fontSize: 32, color: Color(0xFF4A4A4A)),
          ),
          // Fields
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1: Date & NO
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DATE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Container(
                    width: 120,
                    height: 26,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
                    child: InkWell(
                      onTap: _pickReceiptDate,
                      child: Row(
                        children: [
                          Expanded(child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(_dateCtrl.text, style: const TextStyle(fontSize: 12)),
                          )),
                          Container(color: Colors.grey.shade200, width: 20, child: const Icon(Icons.calendar_today, size: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('SALE NO.', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Container(
                    width: 120,
                    height: 26,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
                    padding: const EdgeInsets.only(left: 4),
                    alignment: Alignment.centerLeft,
                    child: Text(_numberCtrl.text, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Column 2: Payment Method
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PAYMENT METH', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Container(
                    width: 150,
                    height: 28,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), color: Colors.white),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _paymentMethod,
                        isExpanded: true,
                        icon: Container(
                          width: 20,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.arrow_drop_down, size: 16),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Cash', child: Padding(padding: EdgeInsets.only(left: 4), child: Text('Cash', style: TextStyle(fontSize: 12)))),
                          DropdownMenuItem(value: 'Check', child: Padding(padding: EdgeInsets.only(left: 4), child: Text('Check', style: TextStyle(fontSize: 12)))),
                          DropdownMenuItem(value: 'BankTransfer', child: Padding(padding: EdgeInsets.only(left: 4), child: Text('Bank Transfer', style: TextStyle(fontSize: 12)))),
                          DropdownMenuItem(value: 'CreditCard', child: Padding(padding: EdgeInsets.only(left: 4), child: Text('Credit Card', style: TextStyle(fontSize: 12)))),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _paymentMethod = val;
                              _preview = null;
                            });
                            _schedulePreview();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('CHECK NO.', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                      _buildRedDot(),
                    ],
                  ),
                  Container(
                    width: 150,
                    height: 26,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), color: Colors.white),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left: Memos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('CUSTOMER MESSAGE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    _buildRedDot(),
                  ],
                ),
                Container(
                  height: 40,
                  width: 250,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), color: const Color(0xFFF5F5F5)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('MEMO', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    _buildRedDot(),
                  ],
                ),
                Container(
                  height: 22,
                  width: 250,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), color: const Color(0xFFF5F5F5)),
                ),
              ],
            ),
          ),
          
          // Right: Total & Buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 300,
                child: TransactionTotalsFooter(totals: _totals),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _saving ? null : () => _save(closeAfterSave: true),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: const Size(0, 32),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: _saving 
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save & Close', style: TextStyle(color: Colors.black87)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : () => _save(closeAfterSave: false),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: const Size(0, 32),
                      backgroundColor: const Color(0xFF3B73B9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('Save & New', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _clearForm,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: const Size(0, 32),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('Clear', style: TextStyle(color: Colors.black87)),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRightSidebar() {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        border: Border(left: BorderSide(color: Color(0xFFCCCCCC), width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: const Text('Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey.shade700,
                child: const Text('Transaction', style: TextStyle(fontSize: 12, color: Colors.white)),
              ),
            ],
          ),
          const Divider(height: 1, color: Colors.grey),
          
          // Content
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SUMMARY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_selectedCustomer != null)
                      Text('Balance: ${(_customerActivity?.openBalance ?? _selectedCustomer!.balance).toStringAsFixed(2)} ${_selectedCustomer!.currency}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
                    else
                      const Text('Select a customer', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('RECENT TRANSACTIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_customerActivity != null && _customerActivity!.recentSalesReceipts.isNotEmpty)
                      ..._customerActivity!.recentSalesReceipts.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text('${_formatDate(e.date)} - ${e.number}', style: const TextStyle(fontSize: 11)),
                      ))
                    else
                      const Text('No recent activity', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('NOTES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        _buildRedDot(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
\n"""

# 560 is return GestureDetector
# 1058 is ); (end of GestureDetector)
del lines[559:1058]
lines.insert(559, new_content)

with open(file_path, "w", encoding="utf-8") as f:
    f.writelines(lines)

print("Replaced lines successfully!")
