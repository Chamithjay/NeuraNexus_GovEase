import 'package:flutter/material.dart';
import 'application_form_screen.dart';

class StreamSelectionScreen extends StatelessWidget {
  final List<StreamOption> streams = [
    StreamOption('Physical Science', Icons.science, Color(0xFF6C5CE7)),
    StreamOption('Biology Science', Icons.biotech, Color(0xFF00B894)),
    StreamOption('Art Stream', Icons.palette, Color(0xFFE17055)),
    StreamOption('Commerce Stream', Icons.business, Color(0xFF74B9FF)),
    StreamOption('Technology Stream', Icons.settings, Color(0xFF2D3436)),
    StreamOption('Common Stream', Icons.book, Color(0xFFFDCB6E)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF3B4B8C),
      appBar: AppBar(
        backgroundColor: Color(0xFF3B4B8C),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'GovEase',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3B4B8C), Color(0xFF4A90E2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Educational Services',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'A/L Admissions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Pick the path that excites you most !\nYour subjects today will shape your tomorrow!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: streams.length,
                    itemBuilder: (context, index) {
                      return _buildStreamCard(context, streams[index]);
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreamCard(BuildContext context, StreamOption stream) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ApplicationFormScreen(selectedStream: stream.name),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: stream.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(stream.icon, size: 30, color: stream.color),
            ),
            SizedBox(height: 12),
            Text(
              stream.name.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class StreamOption {
  final String name;
  final IconData icon;
  final Color color;

  StreamOption(this.name, this.icon, this.color);
}
