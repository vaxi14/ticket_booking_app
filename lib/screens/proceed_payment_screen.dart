import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:ticket_booking_app/models/event_model.dart';
import 'dart:convert';
import 'my_tickets_screen.dart';

class ProceedPaymentScreen extends StatefulWidget {
  final String eventId;
  final String eventName;
  final String seatNumber;
  final int price;
  final Event event;

  const ProceedPaymentScreen({
    Key? key,
    required this.eventId,
    required this.eventName,
    required this.seatNumber,
    required this.price,
    required this.event,
  }) : super(key: key);

  @override
  _ProceedPaymentScreenState createState() => _ProceedPaymentScreenState();
}

class _ProceedPaymentScreenState extends State<ProceedPaymentScreen> {
  String? userEmail;
  String? userName;
  String? userPhone;
  bool isProcessing = false;
  String? temporaryReservationId;

  @override
  void initState() {
    super.initState();
    // Initialize Stripe settings
    _initializeStripe();
    fetchUserDetails();
    // Reserve the seat temporarily when screen is loaded
    if (widget.event.hasSeatLayout && widget.seatNumber != "N/A") {
      _temporarilyReserveSeat();
    }
  }

  @override
  void dispose() {
    // Release temporary reservation if the user leaves the screen
    _releaseSeatIfNeeded();
    super.dispose();
  }

  Future<void> _releaseSeatIfNeeded() async {
    if (temporaryReservationId != null && widget.event.hasSeatLayout) {
      try {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.eventId)
            .collection('seats')
            .doc(widget.seatNumber)
            .update({
          'status': 'available',
          'temporaryReservation': null,
          'reservationTimestamp': null,
        });
        temporaryReservationId = null;
      } catch (e) {
        // Silent error, this is just cleanup
        print("Failed to release seat: $e");
      }
    }
  }

  Future<void> _temporarilyReserveSeat() async {
    if (!widget.event.hasSeatLayout) return;
    
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Generate a unique ID for this reservation
      String reservationId = FirebaseFirestore.instance.collection('temp').doc().id;
      
      // Get the seat reference
      final seatRef = FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('seats')
          .doc(widget.seatNumber);
          
      // Get the seat data
      final seatSnapshot = await seatRef.get();
      
      // Check if seat exists and is available
      if (!seatSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Seat does not exist")),
        );
        return;
      }
      
      // Check if the seat is already reserved
      if (seatSnapshot.data()?['status'] != 'available') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("This seat is no longer available")),
        );
        Navigator.pop(context); // Go back because this seat is not available
        return;
      }
      
      // Set the seat to pending status
      await seatRef.update({
        'status': 'pending',
        'temporaryReservation': reservationId,
        'reservedBy': user.uid,
        'reservationTimestamp': FieldValue.serverTimestamp(),
      });
      
      // Store the reservation ID
      setState(() {
        temporaryReservationId = reservationId;
      });
      
      // Set a timer to release the seat after 10 minutes if payment is not completed
      Future.delayed(const Duration(minutes: 10), () {
        if (temporaryReservationId == reservationId) {
          _releaseSeatIfNeeded();
        }
      });
    } catch (e) {
      print("Error reserving seat: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not reserve seat: ${e.toString()}")),
      );
    }
  }

  Future<void> _initializeStripe() async {
    // Initialize Stripe with your publishable key
    Stripe.publishableKey = 'pk_test_51Qxn0BFxEBWdDqJ6bFeR4BidcihaXOql31VHdzVz3FKJg9Fxm0Dv66kppJkfP3MMiqaS4HEtyfSMCrpYGZUdIlWn00jFZI1B1Z';
    await Stripe.instance.applySettings();
  }

  Future<void> fetchUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          userEmail = userDoc['email'];
          userName = userDoc['name'];
          userPhone = userDoc['phone'];
        });
      }
    }
  }

  Future<void> _proceedPayment() async {
    setState(() => isProcessing = true);

    try {
      // Validate seat selection
      if (widget.event.hasSeatLayout && widget.seatNumber == "N/A") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid seat selection. Please choose a valid seat.")),
        );
        setState(() => isProcessing = false);
        return;
      }

      // Check if our temporary reservation is still valid
      if (widget.event.hasSeatLayout && temporaryReservationId != null) {
        final seatRef = FirebaseFirestore.instance
            .collection('events')
            .doc(widget.eventId)
            .collection('seats')
            .doc(widget.seatNumber);
            
        final seatSnapshot = await seatRef.get();
        
        if (!seatSnapshot.exists || 
            seatSnapshot.data()?['status'] != 'pending' || 
            seatSnapshot.data()?['temporaryReservation'] != temporaryReservationId) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Your seat reservation has expired. Please select another seat.")),
          );
          setState(() => isProcessing = false);
          Navigator.pop(context);
          return;
        }
      }

      // Create payment intent
      final paymentIntent = await createPaymentIntent();
      if (paymentIntent == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create payment. Please try again.")),
        );
        setState(() => isProcessing = false);
        return;
      }

      // Configure the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: "Ticket Booking App",
          style: ThemeMode.dark,
          // Add customer details for a more personalized experience
          customerEphemeralKeySecret: paymentIntent['ephemeral_key'],
          customerId: paymentIntent['customer'],
          // Add billing details if needed
          billingDetails: BillingDetails(
            name: userName,
            email: userEmail,
            phone: userPhone,
          ),
        ),
      );

      // Present the payment sheet to the user
      await Stripe.instance.presentPaymentSheet();

      // If we get here, payment was successful
      bool bookingSuccess = await _createBookingAfterSuccessfulPayment();
      
      if (bookingSuccess) {
        // Clear the temporary reservation since it's now permanently booked
        temporaryReservationId = null;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment Successful! Ticket Booked.")),
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyTicketsScreen()),
        );
      } else {
        // Handle rare case where booking failed after payment
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment was successful, but we couldn't complete your booking. Please contact support.")),
        );
      }
    } catch (e) {
      // Handle payment error
      if (e is StripeException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment failed: ${e.error.localizedMessage}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment failed: ${e.toString()}")),
        );
      }
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<Map<String, dynamic>?> createPaymentIntent() async {
    const String secretKey = "sk_test_51Qxn0BFxEBWdDqJ6ONNc89RTvbQpJr2lqmiMVyL2HqsOmp11K7gUQjeXCIW619Si2J1YCNA56qATZe93mkVhVRLt007reaUAFS";
    
    try {
      // Create a customer for the payment (optional but recommended)
      final customerResponse = await http.post(
        Uri.parse('https://api.stripe.com/v1/customers'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'name': userName,
          'email': userEmail,
          'phone': userPhone,
        },
      );
      final customerData = jsonDecode(customerResponse.body);
      final customerId = customerData['id'];

      // Create an ephemeral key for the customer
      final ephemeralKeyResponse = await http.post(
        Uri.parse('https://api.stripe.com/v1/ephemeral_keys'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Stripe-Version': '2023-10-16', // Use the latest API version
        },
        body: {
          'customer': customerId,
        },
      );
      final ephemeralKeyData = jsonDecode(ephemeralKeyResponse.body);
      final ephemeralKey = ephemeralKeyData['secret'];

      // Calculate the total amount including convenience fee
      int convenienceFee = 1;
      int totalAmount = widget.price + convenienceFee;

      // Create the payment intent
      final paymentIntentResponse = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (totalAmount * 100).toString(),
          'currency': 'inr',
          'customer': customerId,
          'automatic_payment_methods[enabled]': 'true',
          'description': 'Ticket for ${widget.eventName}',
          'metadata[event_id]': widget.eventId,
          'metadata[seat_number]': widget.seatNumber,
          'metadata[reservation_id]': temporaryReservationId ?? '',
        },
      );
      
      final paymentIntentData = jsonDecode(paymentIntentResponse.body);
      return {
        'client_secret': paymentIntentData['client_secret'],
        'customer': customerId,
        'ephemeral_key': ephemeralKey,
      };
    } catch (e) {
      print('Error creating payment intent: $e');
      return null;
    }
  }

  Future<bool> _createBookingAfterSuccessfulPayment() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        if (widget.event.hasSeatLayout) {
          final seatRef = FirebaseFirestore.instance
              .collection('events')
              .doc(widget.eventId)
              .collection('seats')
              .doc(widget.seatNumber);

          final seatSnapshot = await transaction.get(seatRef);

          // Check if seat exists and has our temporary reservation
          if (!seatSnapshot.exists) {
            throw Exception("Seat does not exist");
          }
          
          final seatData = seatSnapshot.data()!;
          
          // Allow booking only if the seat is pending with our reservation ID,
          // or if it's available (as a fallback)
          if (seatData['status'] == 'pending' && seatData['temporaryReservation'] == temporaryReservationId) {
            transaction.update(seatRef, {
              'status': 'booked',
              'bookedBy': user.uid,
              'temporaryReservation': null,
              'reservationTimestamp': null,
              'bookingTimestamp': FieldValue.serverTimestamp(),
            });
          } else if (seatData['status'] == 'available') {
            transaction.update(seatRef, {
              'status': 'booked',
              'bookedBy': user.uid,
              'bookingTimestamp': FieldValue.serverTimestamp(),
            });
          } else {
            throw Exception("Seat is no longer available for booking");
          }
        }

        final bookingRef = FirebaseFirestore.instance.collection('bookings').doc();
        transaction.set(bookingRef, {
          'eventId': widget.eventId,
          'eventName': widget.eventName,
          'userId': user.uid,
          'userEmail': userEmail,
          'userName': userName,
          'userPhone': userPhone,
          'seatNumber': widget.event.hasSeatLayout ? widget.seatNumber : 'General',
          'price': widget.price,
          'status': 'Confirmed',
          'timestamp': FieldValue.serverTimestamp(),
          'bookingId': bookingRef.id,  // Store the booking ID for easier reference
          'paymentMethod': 'Stripe',
        });
      });
      return true;
    } catch (e) {
      print("Error during booking creation: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    int convenienceFee = 1;
    int orderTotal = widget.price + convenienceFee;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Confirm Booking", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Event Name and Seat Number
              _buildCard([
                Text(widget.eventName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text("Seat: ${widget.event.hasSeatLayout ? widget.seatNumber : 'General Admission'}", style: const TextStyle(color: Colors.white70)),
                const Text("Event Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("📍 Location: ${widget.event.location}", style: const TextStyle(color: Colors.white70)),
                Text("🕒 Date: ${widget.event.date}", style: const TextStyle(color: Colors.white70)),
              ]),

              _buildCard([
                const Text("Your Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("👤 Name: $userName", style: const TextStyle(color: Colors.white70)),
                Text("📧 Email: $userEmail", style: const TextStyle(color: Colors.white70)),
                Text("📞 Phone: $userPhone", style: const TextStyle(color: Colors.white70)),
              ]),

              // Card 2: Price Breakdown
              _buildCard([
                const Text("Price Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("🎟 Ticket Price: ₹${widget.price}", style: const TextStyle(color: Colors.white70)),
                Text("⚡ Convenience Fee: ₹$convenienceFee", style: const TextStyle(color: Colors.white70)),
                Text("💰 Total: ₹$orderTotal", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ]),

              const Spacer(),
              ElevatedButton(
                onPressed: isProcessing ? null : _proceedPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Continue to Pay",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}