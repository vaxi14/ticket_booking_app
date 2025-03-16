import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ticket_booking_app/models/event_model.dart';
import 'package:ticket_booking_app/screens/proceed_payment_screen.dart';

class BookMyTicketScreen extends StatefulWidget {
  final Event event;

  BookMyTicketScreen({required this.event});

  @override
  _BookMyTicketScreenState createState() => _BookMyTicketScreenState();
}

class _BookMyTicketScreenState extends State<BookMyTicketScreen> {
  String? selectedSeat;
  int seatPrice = 500;
  Set<String> bookedSeats = {};

  @override
  void initState() {
    super.initState();
    fetchSeatPrice();
    fetchBookedSeats();
  }

  Future<void> fetchSeatPrice() async {
    try {
      DocumentSnapshot eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .get();

      if (eventDoc.exists && eventDoc.data() != null) {
        Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
        setState(() {
          seatPrice = eventData["price"] ?? 500;
        });
      }
    } catch (e) {
      print("Error fetching seat price: $e");
    }
  }

  Future<void> fetchBookedSeats() async {
    try {
      QuerySnapshot bookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('eventId', isEqualTo: widget.event.id)
          .get();
      setState(() {
        bookedSeats = bookings.docs.map((doc) => doc['seatNumber'] as String).toSet();
      });
    } catch (e) {
      print("Error fetching booked seats: $e");
    }
  }

  void selectSeat(String seatId) {
    if (!bookedSeats.contains(seatId)) {
      setState(() {
        selectedSeat = seatId;
      });
    }
  }

  Future<void> saveSelectionToFirebase() async {
    if (selectedSeat == null) return;
    bool paymentSuccess = await processStripePayment();
    if (!paymentSuccess) {
      print("Payment failed. Booking not created.");
      return;
    }
    await FirebaseFirestore.instance.collection('bookings').add({
      'eventId': widget.event.id,
      'eventName': widget.event.name,
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'seatNumber': selectedSeat,
      'price': seatPrice,
      'status': 'Confirmed',
      'timestamp': FieldValue.serverTimestamp(),
    });
    print("Ticket booked successfully!");
  }

  Future<bool> processStripePayment() async {
    try {
      await Future.delayed(Duration(seconds: 2));
      return true;
    } catch (error) {
      print("Stripe Payment Error: $error");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Book Tickets",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.event.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green, size: 18),
                const SizedBox(width: 6),
                Text(widget.event.location, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.green, size: 18),
                const SizedBox(width: 6),
                Text(widget.event.date, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Seat Price: ₹$seatPrice",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                "SCREEN",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const Divider(color: Colors.white, thickness: 1),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: List.generate(40, (rowIndex) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(20, (colIndex) {
                          String seatId = "S${rowIndex * 20 + colIndex + 1}";
                          bool isSelected = selectedSeat == seatId;
                          bool isBooked = bookedSeats.contains(seatId);
                          return GestureDetector(
                            onTap: () {
                              if (!isBooked) selectSeat(seatId);
                            },
                            child: Container(
                              width: 30,
                              height: 30,
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isBooked
                                    ? Colors.red
                                    : (isSelected ? Colors.green : Colors.grey[800]),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                seatId,
                                style: TextStyle(color: isBooked ? Colors.black : Colors.white, fontSize: 10),
                              ),
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (selectedSeat != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    await saveSelectionToFirebase();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProceedPaymentScreen(
                          event: widget.event,
                          seatNumber: selectedSeat!,
                          price: seatPrice,
                          eventId: widget.event.id,
                          eventName: widget.event.name,
                        ),
                      ),
                    );
                  },
                  child: const Text("Proceed to Payment"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}