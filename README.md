# Magazam - Inventory Management System

A comprehensive inventory management system built with Flutter for the frontend and Node.js for the backend.

## 📱 Features

- **Customer Management**: Add, edit, and manage customer information
- **Stock Management**: Track inventory, add/remove items, monitor stock levels
- **Invoice Management**: Create, edit, and manage invoices with automatic calculations
- **User Authentication**: Secure login system with JWT tokens
- **Real-time Updates**: Live inventory tracking and updates
- **Responsive Design**: Works on mobile, tablet, and desktop

## 🏗️ Project Structure

```
magazam/
├── magazam/                 # Flutter Mobile Application
│   ├── lib/
│   │   ├── bloc/           # BLoC state management
│   │   ├── models/         # Data models
│   │   ├── repositories/   # Data repositories
│   │   ├── screens/        # UI screens
│   │   └── services/       # API services
│   ├── android/            # Android specific files
│   ├── ios/               # iOS specific files
│   └── pubspec.yaml       # Flutter dependencies
├── magazam_server/         # Node.js Backend Server
│   ├── controllers/        # API controllers
│   ├── models/            # Database models
│   ├── routes/            # API routes
│   ├── middleware/        # Authentication middleware
│   └── package.json       # Node.js dependencies
└── screenshots/           # Application screenshots
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Node.js (>=16.0.0)
- MongoDB
- Git

### Backend Setup (magazam_server)

1. Navigate to the server directory:
   ```bash
   cd magazam_server
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create a `.env` file with your configuration:
   ```env
   PORT=3000
   MONGODB_URI=mongodb://localhost:27017/magazam
   JWT_SECRET=your_jwt_secret_here
   ```

4. Start the server:
   ```bash
   npm start
   ```

### Frontend Setup (magazam)

1. Navigate to the Flutter app directory:
   ```bash
   cd magazam
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```


## 🛠️ Technologies Used

### Frontend (Flutter)
- **Flutter**: Cross-platform mobile framework
- **BLoC**: State management
- **HTTP**: API communication
- **Shared Preferences**: Local storage
- **Material Design**: UI components

### Backend (Node.js)
- **Express.js**: Web framework
- **MongoDB**: Database
- **Mongoose**: ODM for MongoDB
- **JWT**: Authentication
- **Bcrypt**: Password hashing
- **CORS**: Cross-origin resource sharing

## 📊 Database Schema

### User
- id, username, email, password, role, createdAt, updatedAt

### Customer
- id, fullName, email, phone, address, createdAt, updatedAt

### Stock Item
- id, name, description, price, quantity, category, createdAt, updatedAt

### Invoice
- id, invoiceNumber, customerId, items[], totalAmount, status, createdAt, updatedAt

## 🔧 API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration

### Customers
- `GET /api/customers` - Get all customers
- `POST /api/customers` - Create customer
- `PUT /api/customers/:id` - Update customer
- `DELETE /api/customers/:id` - Delete customer

### Stock
- `GET /api/stock` - Get all stock items
- `POST /api/stock` - Create stock item
- `PUT /api/stock/:id` - Update stock item
- `DELETE /api/stock/:id` - Delete stock item

### Invoices
- `GET /api/invoices` - Get all invoices
- `POST /api/invoices` - Create invoice
- `PUT /api/invoices/:id` - Update invoice
- `DELETE /api/invoices/:id` - Delete invoice

## 📝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Your Name**
- GitHub: [@i4rcu](https://github.com/i4rcu)
- LinkedIn: [Your LinkedIn](https://linkedin.com/in/yourprofile)
- Email: your.email@example.com

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- MongoDB for the reliable database
- Express.js community for the excellent web framework
