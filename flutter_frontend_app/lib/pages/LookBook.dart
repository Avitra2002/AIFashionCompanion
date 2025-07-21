
import 'package:flutter/material.dart';
import 'package:flutter_frontend_app/services/api.dart';
import 'package:flutter_frontend_app/pages/lookDetail.dart';

class LookBookPage extends StatefulWidget {
  const LookBookPage({super.key});

  @override
  State<LookBookPage> createState() => _LookBookPageState();
}

class _LookBookPageState extends State<LookBookPage> {
  List<Map<String, dynamic>> _looks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLooks();
  }
  Future<void> _fetchLooks() async {
    try {
      final looks = await ApiService.getSavedLooks();
      setState(() { // rebuild UI
        _looks = looks;
        _loading = false;
      });
    } catch (e) {
      print(e);
    }
  }


  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Theme.of(context).colorScheme.secondary, 
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Text(
                  "📘 Look Book",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _looks.length,
                    itemBuilder: (context, index) {
                      final look = _looks[index];
                      final collageUrl = look['collage_url'];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LookDetailPage(look: look)),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: collageUrl != null
                                    ? Image.network(
                                        collageUrl,
                                        width: double.infinity,
                                        height: 200,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        height: 200,
                                        color: Theme.of(context).colorScheme.surface,
                                        child: const Center(child: Text('No image')),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  look['look_name'] ?? 'Unnamed Look',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.secondary)
                                ),
                              ),
                            ],
                          ),
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

}
