import 'package:flutter/material.dart';

class FormPlaygroundScreen extends StatelessWidget {
  const FormPlaygroundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Ribbon Area (Top Bar)
          _buildRibbon(),
          
          // 2. Dark Blue Bar
          _buildBlueBar(),
          
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
                      Expanded(child: _buildDataGrid()),
                      
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
                _buildRibbonTab('Formatting'),
                _buildRibbonTab('Reports'),
                _buildRibbonTab('Search'),
                const Spacer(),
                const Icon(Icons.fullscreen, size: 16, color: Colors.black54),
                const SizedBox(width: 8),
                const Icon(Icons.close, size: 16, color: Colors.black54),
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
                _buildRibbonButton(Icons.search, 'Find', isBlue: true),
                const SizedBox(width: 8),
                _buildRibbonButton(Icons.note_add, 'New'),
                _buildRibbonButton(Icons.save, 'Save'),
                _buildRibbonButton(Icons.delete_forever, 'Delete'),
                _buildRibbonButton(Icons.copy, 'Create a Copy'),
                _buildRibbonButton(Icons.check_circle_outline, 'Memorize'),
                const SizedBox(width: 16),
                _buildRibbonButton(Icons.print, 'Print'),
                _buildRibbonButton(Icons.email, 'Email'),
                const SizedBox(width: 16),
                _buildRibbonButton(Icons.attach_file, 'Attach\nFile'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRibbonTab(String text, {bool isActive = false}) {
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
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? Colors.black : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildRibbonButton(IconData icon, String label, {bool isBlue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: isBlue ? Colors.blue.shade700 : Colors.blue.shade600),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildBlueBar() {
    return Container(
      color: const Color(0xFF5B7B9E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Text('VENDOR', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          _buildDropdown(width: 200),
          const SizedBox(width: 24),
          const Text('DROP SHIP TO', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          _buildDropdown(width: 150),
          const SizedBox(width: 24),
          const Text('TEMPLATE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          _buildDropdown(width: 150, value: 'Custom Purch...'),
        ],
      ),
    );
  }

  Widget _buildDropdown({required double width, String value = ''}) {
    return Container(
      width: width,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Row(
        children: [
          Expanded(child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(value, style: const TextStyle(fontSize: 12)),
          )),
          Container(
            width: 16,
            color: Colors.grey.shade300,
            child: const Icon(Icons.arrow_drop_down, size: 16),
          )
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
            'Purchase Order',
            style: TextStyle(fontSize: 32, color: Color(0xFF4A4A4A)),
          ),
          // Fields
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1: Date & PO NO
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DATE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Container(
                    width: 100,
                    height: 22,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
                    child: Row(
                      children: [
                        const Expanded(child: Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text('09/05/2026', style: TextStyle(fontSize: 12)),
                        )),
                        Container(color: Colors.grey.shade200, width: 20, child: const Icon(Icons.calendar_today, size: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('P.O. NO.', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Container(
                    width: 100,
                    height: 22,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
                    padding: const EdgeInsets.only(left: 4),
                    alignment: Alignment.centerLeft,
                    child: const Text('3', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Column 2: Vendor
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('VENDOR', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Container(
                    width: 150,
                    height: 70,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), color: const Color(0xFFF5F5F5)),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Column 3: Ship To
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('SHIP TO', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 48),
                      Container(width: 50, height: 16, color: Colors.white, child: const Icon(Icons.arrow_drop_down, size: 16)),
                    ],
                  ),
                  Container(
                    width: 150,
                    height: 70,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), color: const Color(0xFFF5F5F5)),
                    padding: const EdgeInsets.all(4),
                    child: const Text('zayed', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDataGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Column(
          children: [
            // Header
            Container(
              height: 24,
              color: Colors.white,
              child: const Row(
                children: [
                  Expanded(flex: 2, child: _GridHeaderCell('ITEM')),
                  Expanded(flex: 4, child: _GridHeaderCell('DESCRIPTION')),
                  Expanded(flex: 1, child: _GridHeaderCell('QTY')),
                  Expanded(flex: 1, child: _GridHeaderCell('RATE')),
                  Expanded(flex: 2, child: _GridHeaderCell('CUSTOMER')),
                  Expanded(flex: 2, child: _GridHeaderCell('AMOUNT')),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.grey),
            // Rows
            Expanded(
              child: ListView.builder(
                itemCount: 15,
                itemBuilder: (context, index) {
                  final isEven = index % 2 == 0;
                  return Container(
                    height: 24,
                    color: isEven ? Colors.white : const Color(0xFFE6F0F9),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Container(decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300))))),
                        Expanded(flex: 4, child: Container(decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300))))),
                        Expanded(flex: 1, child: Container(decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300))))),
                        Expanded(flex: 1, child: Container(decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300))))),
                        Expanded(flex: 2, child: Container(decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300))))),
                        Expanded(flex: 2, child: Container()),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
                const Text('VENDOR MESSAGE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                Container(
                  height: 40,
                  width: 250,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), color: const Color(0xFFF5F5F5)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('MEMO', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      height: 22,
                      width: 200,
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), color: const Color(0xFFF5F5F5)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Right: Total & Buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('TOTAL', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: const Size(0, 32),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('Save & Close', style: TextStyle(color: Colors.black87)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {},
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
                    onPressed: () {},
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SUMMARY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  SizedBox(height: 100),
                  Divider(),
                  SizedBox(height: 8),
                  Text('RECENT TRANSACTIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  SizedBox(height: 100),
                  Divider(),
                  SizedBox(height: 8),
                  Text('NOTES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _GridHeaderCell extends StatelessWidget {
  final String title;
  const _GridHeaderCell(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      alignment: Alignment.bottomLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
      ),
    );
  }
}
