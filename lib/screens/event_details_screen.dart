import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ticket_booking_app/models/event_model.dart';
import 'package:ticket_booking_app/screens/book_my_ticket_screen.dart';
import 'package:ticket_booking_app/screens/proceed_payment_screen.dart';

class EventDetailsScreen extends StatelessWidget {
  final Event event;

  const EventDetailsScreen({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(event.name,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('events').doc(event.id).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("Event details not available",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            );
          }

          var eventData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          bool hasSeatLayout = eventData["hasSeatLayout"] ?? false;
          String eventDate = eventData["date"]?.toString() ?? "Date Not Available";
          String formattedTime = eventData["time"]?.toString() ?? "Time Not Available";
          String price = eventData["price"]?.toString() ?? "N/A";
          String aboutEvent = eventData["about"] ?? "No details available.";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(event.imageUrl,
                      width: double.infinity, height: 220, fit: BoxFit.cover),
                ),
                const SizedBox(height: 16),

                Text(event.name,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),

                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Text(event.location, style: TextStyle(fontSize: 16, color: Colors.grey[400])),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Text(eventDate, style: TextStyle(fontSize: 16, color: Colors.grey[400])),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.watch_later, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(formattedTime, style: TextStyle(fontSize: 16, color: Colors.grey[400])),
                  ],
                ),
                const SizedBox(height: 13),

                Text("Price: ₹$price",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 20),

                const Text("About the Event",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                Text(aboutEvent,
                    style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                    textAlign: TextAlign.justify),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () async {
            DocumentSnapshot eventSnapshot =
                await FirebaseFirestore.instance.collection('events').doc(event.id).get();
            bool hasSeatLayout = eventSnapshot["hasSeatLayout"] ?? false;
            
            if (hasSeatLayout) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BookMyTicketScreen(event: event)),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProceedPaymentScreen(event: event, eventId: event.id, eventName: event.name, seatNumber: 'N/A', price: event.price.toInt())),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text("Book Ticket",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}
