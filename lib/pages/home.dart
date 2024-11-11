import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safesync/pages/account_page.dart';
import 'package:safesync/pages/reports_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const SafeSyncDashboard());

class SafeSyncDashboard extends StatefulWidget {
  const SafeSyncDashboard({super.key});

  @override
  State<SafeSyncDashboard> createState() => _SafeSyncDashboardState();
}

class _SafeSyncDashboardState extends State<SafeSyncDashboard> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final _pages = [
    const SafeSyncBody(),
    ReportsPage(),
  ];

  final _navItems = const [
    BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.home), label: 'Dashboard'),
    BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.doc_append), label: 'Report'),
    BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.list_dash), label: 'Incidents'),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blueAccent,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: _selectedIndex == 0 ? buildAppBar() : null,
        body: SafeArea(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _selectedIndex = index),
            children: _pages,
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: _navItems,
        ),
      ),
    );
  }
}

AppBar buildAppBar() {
  return AppBar(
    backgroundColor: Colors.white,
    title: Text("Safesync",
        style: textStyle(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: Colors.blueAccent)),
    elevation: 1,
  );
}

class SafeSyncBody extends StatelessWidget {
  const SafeSyncBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildDashboardButton(context),
        const SizedBox(height: 20),
        _buildSectionTitle("Recent Activity"),
        _buildActivityRow(),
        const SizedBox(height: 20),
        _buildSectionTitle("Recent Incidents"),
        _buildIncidentCard("Vehicle Accident", "On Main Street", "In Progress"),
        _buildIncidentCard("Road Hazard", "At Junction A", "Acknowledged"),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child:
          Text(title, style: textStyle(fontSize: 22, color: Colors.blueAccent)),
    );
  }

  Widget _buildDashboardButton(BuildContext context) {
    return FutureBuilder<Map<String, String?>>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading data'));
        }
        final userData = snapshot.data;
        return Card(
          color: Colors.blueAccent,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AccountDashboard())),
            leading: const Icon(CupertinoIcons.profile_circled,
                size: 50, color: Colors.white),
            title: Text(userData?['name'] ?? 'Officer Name',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white)),
            subtitle: Text("Officer: ${userData?['position'] ?? 'N/A'}"),
            textColor: Colors.white70,
          ),
        );
      },
    );
  }

  Widget _buildActivityRow() {
    return Row(
      children: [
        Expanded(
            child:
                _buildActivityCard("Incident Report", "5 reports submitted")),
        const SizedBox(width: 10),
        Expanded(child: _buildActivityCard("Notifications", "2 new alerts")),
      ],
    );
  }

  Widget _buildActivityCard(String title, String description) {
    return Card(
      color: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentCard(String incident, String location, String status) {
    return Card(
      color: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(incident, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Location: $location"),
            const SizedBox(height: 4),
            Text("Status: $status"),
          ],
        ),
      ),
    );
  }

  Future<Map<String, String?>> _getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('name'),
      'position': prefs.getString('position'),
      'number': prefs.getString('number'),
    };
  }
}

TextStyle textStyle({double? fontSize, FontWeight? fontWeight, Color? color}) {
  return GoogleFonts.poppins(
      fontSize: fontSize, fontWeight: fontWeight, color: color);
}
