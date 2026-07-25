# 🚚 QuickParcel

A courier delivery mobile application developed as a Final Year Project using Flutter and Firebase.

---

## 📖 Project Overview

QuickParcel is a courier delivery mobile application designed to simplify parcel delivery services by connecting customers, delivery drivers, and administrators through a single platform.

The application enables customers to book parcels, track deliveries, and communicate with assigned drivers. Delivery drivers can manage delivery requests and update parcel status, while administrators oversee user management and system operations.

This project was developed as part of the Final Year Project for the Bachelor of Science in Computer Science and Engineering.

---

## 🎯 Project Objectives

- Simplify parcel booking and delivery management.
- Connect customers and delivery drivers efficiently.
- Provide real-time parcel tracking.
- Improve communication between customers and drivers.
- Build a secure and user-friendly mobile application.


---

## 🛠 Technology Stack

| Category | Technologies |
|----------|--------------|
| Mobile App | Flutter |
| Backend | Firebase |
| Database | Cloud Firestore |
| Authentication | Firebase Authentication |
| UI Design | Figma |
| Programming Language | Dart |

---

## ✨ Key Features

### Customer
- User Registration & Login
- Parcel Booking
- Delivery Tracking
- Driver Communication
- Profile Management

### Driver
- Driver Login
- Receive Delivery Requests
- Update Parcel Status
- Share Live Location
- Customer Communication

### Admin
- Admin Login
- Manage Users
- Manage Delivery Drivers
- Monitor Parcel Activities


## 📊 System Workflow

QuickParcel consists of three main modules: Customer, Driver, and Admin.

### Customer Workflow

![Customer Workflow](documents/flowchart/customer-workflow.png)

---

### Driver Workflow

![Driver Workflow](documents/flowchart/driver-workflow.png)

---

### Admin Workflow

![Admin Workflow](documents/flowchart/admin-workflow.png)


---

## 📱 Customer Module

The following screenshots demonstrate the main workflow of the customer application.

### 1. Splash Screen

![Splash Screen](screenshots/customer/01_splash_screen.png)

---

### 2. Login

![Login](screenshots/customer/02_login_screen.png)

---

### 3. Sign Up

![Sign Up](screenshots/customer/03_signup_screen.png)

---

### 4. Home Screen

![Home Screen](screenshots/customer/04_home_screen.png)

---

### 5. Parcel Services

![Parcel Services](screenshots/customer/05_parcel_services.png)

---

### 6. Driver Selection

![Driver Selection](screenshots/customer/06_driver_selection.png)

---

### 7. Driver Details

![Driver Details](screenshots/customer/07_driver_details.png)

---

### 8. Online Payment

![Online Payment](screenshots/customer/08_online_payment.png)

---

### 9. Live Tracking

![Live Tracking](screenshots/customer/09_live_tracking.png)


---

## 🚚 Driver Module

The Driver Module enables delivery personnel to receive parcel requests, manage assigned deliveries, and update delivery status throughout the delivery process.

### 1. Driver Login

![Driver Login](screenshots/driver/01_driver_login.png)

---

### 2. Driver Registration

![Driver Registration](screenshots/driver/02_driver_registration.png)

---

### 3. Driver Dashboard

![Driver Dashboard](screenshots/driver/03_driver_dashboard.jpg)

---

### 4. Pending Orders

![Pending Orders](screenshots/driver/04_pending_orders.jpg)

---

### 5. Active Order

![Active Order](screenshots/driver/05_active_order.jpg)


---

### 6. Delivery Status

![Delivery Status](screenshots/driver/06_delivery_status.jpg)


---

## 🛠 Admin Module

The Admin Module allows administrators to manage customers, drivers, parcel assignments, and overall system operations.

### 1. Admin Login

![Admin Login](screenshots/admin/01_admin_login.png)

---

### 2. Admin Dashboard

![Admin Dashboard](screenshots/admin/02_admin_dashboard.png)

---

### 3. Customer Management

![Customer Management](screenshots/admin/03_customer_management.png)

---

### 4. Driver Management

![Driver Management](screenshots/admin/04_driver_management.png)

---

### 5. Delivery Assignment

![Delivery Assignment](screenshots/admin/05_delivery_assignment.png)

---

### 6. Parcel Management

![Parcel Management](screenshots/admin/06_parcel_management.png)


---

## 📂 Project Structure

```text
QuickParcel/
├── android/
├── ios/
├── lib/
├── assets/
├── screenshots/
│   ├── customer/
│   ├── driver/
│   └── admin/
├── documents/
│   ├── flowchart/
│   └── proposal/
├── pubspec.yaml
├── README.md
└── LICENSE
```

The project is developed as a single Flutter application. Customer, Driver, and Admin functionalities are organized as separate modules within the application.
