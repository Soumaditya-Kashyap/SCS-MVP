import 'package:flutter/material.dart';
import '../../utils/admin_account_setup.dart';

/// ONE-TIME ADMIN SETUP SCREEN
/// Use this screen ONCE to create the 6 preset admin accounts
/// This is now automated - just click the button!

class AdminSetupScreen extends StatefulWidget {
  const AdminSetupScreen({super.key});

  @override
  State<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen> {
  bool _isLoading = false;
  String _statusMessage = '';
  Map<String, dynamic>? _results;

  Future<void> _runSetup() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating 6 preset admin accounts...';
      _results = null;
    });

    try {
      final results = await AdminAccountSetup.setupPresetAdminAccounts();

      setState(() {
        _results = results;
        final summary = results['summary'] as Map<String, dynamic>;
        _statusMessage =
            'Setup complete! ${summary['success']} accounts created successfully.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Setup failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preset Admin Setup'),
        backgroundColor: Colors.orange,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700], size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'ONE-TIME SETUP',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click the button below to automatically create 6 preset admin accounts.',
                        style: TextStyle(color: Colors.orange[900]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Preset Credentials List
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Accounts to be Created:',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildCredRow('CSE', 'cseadtu@admin.in', 'cse1234'),
                      _buildCredRow('ECE', 'eceadtu@admin.in', 'ece1234'),
                      _buildCredRow('ME', 'meadtu@admin.in', 'me1234'),
                      _buildCredRow('CE', 'ceadtu@admin.in', 'ce1234'),
                      _buildCredRow('EE', 'eeadtu@admin.in', 'ee1234'),
                      _buildCredRow('IT', 'itadtu@admin.in', 'it1234'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Setup Button
              ElevatedButton(
                onPressed: _isLoading ? null : _runSetup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create All Admin Accounts',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 24),

              // Status Message
              if (_statusMessage.isNotEmpty)
                Card(
                  color: _results != null ? Colors.green[50] : Colors.grey[100],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _results != null
                            ? Colors.green[900]
                            : Colors.grey[900],
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              // Results Details
              if (_results != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Results:',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ..._results!.entries
                            .where((e) => e.key != 'summary')
                            .map((entry) {
                              final isSuccess = entry.value.toString().contains(
                                'successfully',
                              );
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSuccess
                                          ? Icons.check_circle
                                          : Icons.error,
                                      color: isSuccess
                                          ? Colors.green
                                          : Colors.orange,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${entry.key}: ${entry.value}',
                                        style: TextStyle(
                                          color: isSuccess
                                              ? Colors.green[900]
                                              : Colors.orange[900],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Info Card
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'After Setup',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• Each department gets one admin account',
                        style: TextStyle(color: Colors.blue[900]),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• Teachers login using department credentials',
                        style: TextStyle(color: Colors.blue[900]),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• This setup needs to be run only ONCE',
                        style: TextStyle(color: Colors.blue[900]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCredRow(String dept, String email, String password) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              dept,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              '$email / $password',
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
