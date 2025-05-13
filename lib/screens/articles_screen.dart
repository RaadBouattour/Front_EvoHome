import 'package:evo_home_app/services/api_service.dart';
import 'package:flutter/material.dart';

class ArticlesScreen extends StatelessWidget {
  const ArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          future: ApiService().fetchTips(),  // Create an instance and call fetchTips() here
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No articles found.'));
            }

            final tips = snapshot.data!;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Discover Articles',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Stay up-to-date with the latest trends in smart living, automation, and IoT.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                ...tips.map((tip) => _buildArticleCard(context, tip)).toList(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, dynamic tip) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(
                    label: Text(tip['category']),
                    backgroundColor: Colors.blue.shade50,
                    labelStyle: const TextStyle(color: Colors.blue),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tip['title'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tip['description'],
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
