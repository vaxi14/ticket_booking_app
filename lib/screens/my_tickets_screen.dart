import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyTicketsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text("My Tickets", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
        ),
        body: Center(
          child: Text(
            "Please log in to see your tickets",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("My Tickets", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'Confirmed')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading tickets",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }

          var tickets = snapshot.data?.docs ?? [];
          if (tickets.isEmpty) {
            return Center(
              child: Text(
                "No tickets booked",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              return _buildTicketCard(tickets[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(DocumentSnapshot ticket) {
    var data = ticket.data() as Map<String, dynamic>? ?? {};
    String eventName = data['eventName'] ?? 'Event Name Missing';
    String price = data['price']?.toString() ?? '0';
    String seatNumber = data['seatNumber'] ?? 'N/A';
    String ticketId = ticket.id;
    String eventId = data['eventId'] ?? '';
    String date = data['date'] ?? '';

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('events').doc(eventId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Text("Error fetching event details", style: TextStyle(color: Colors.white));
        }

        var eventData = snapshot.data!.data() as Map<String, dynamic>;
        String location = eventData['location'] ?? 'Unknown Location';
        String time = eventData['time'] ?? 'Unknown Time';
        String date = eventData['date'] ?? 'Unknown Date';

        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 5, spreadRadius: 2)],
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eventName,
                style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildIconText(Icons.location_on, location, Colors.black54),
                  _buildIconText(Icons.access_time, time, Colors.black54),
                  
                  
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "₹$price",
                    style: TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Seat: $seatNumber",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Divider(color: Colors.grey[400], thickness: 1),
              SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: ticketId,
                        version: QrVersions.auto,
                        size: 150.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Show this QR code at entry",
                      style: TextStyle(color: Colors.black54, fontSize: 14, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIconText(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontSize: 14)),
      ],
    );
  }
}
