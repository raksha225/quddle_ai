# 🏪 Store Section - File Architecture

## 📁 **Frontend Architecture (Flutter)**

### **Services First** (as requested)
```
lib/services/store/
├── store_service.dart              # Main store API service
├── product_service.dart            # Product management
├── cart_service.dart               # Shopping cart operations
├── order_service.dart              # Order management
├── seller_service.dart             # Seller operations
├── category_service.dart          # Product categories
├── review_service.dart             # Product reviews
└── payment_service.dart            # Payment processing
```

### **Models**
```
lib/models/store/
├── product_model.dart              # Product data model
├── cart_model.dart                 # Cart item model
├── order_model.dart                # Order data model
├── seller_model.dart               # Seller profile model
├── category_model.dart             # Category model
├── review_model.dart               # Review model
├── payment_model.dart              # Payment data model
└── store_response_model.dart       # API response models
```

### **Screens**
```
lib/screen/store/
├── store_home_screen.dart          # Main store landing
├── product_list_screen.dart        # Product listing
├── product_detail_screen.dart      # Product details
├── cart_screen.dart                # Shopping cart
├── checkout_screen.dart            # Checkout process
├── order_history_screen.dart       # Order history
├── seller/
│   ├── seller_dashboard.dart       # Seller dashboard
│   ├── add_product_screen.dart     # Add new product
│   ├── edit_product_screen.dart    # Edit product
│   ├── seller_orders_screen.dart   # Seller order management
│   └── seller_analytics_screen.dart # Sales analytics
├── category/
│   ├── category_list_screen.dart   # Browse categories
│   └── category_products_screen.dart # Products by category
└── search/
    ├── search_screen.dart          # Product search
    └── search_results_screen.dart  # Search results
```

### **Components**
```
lib/components/store/
├── product_card.dart               # Product display card
├── cart_item.dart                  # Cart item component
├── category_chip.dart              # Category selection
├── product_image.dart              # Product image display
├── price_display.dart              # Price formatting
├── rating_stars.dart               # Star rating component
├── seller/
│   ├── seller_card.dart            # Seller profile card
│   ├── product_form.dart          # Product creation form
│   └── order_status_card.dart      # Order status display
└── common/
    ├── store_app_bar.dart          # Store-specific app bar
    ├── store_bottom_nav.dart      # Store navigation
    └── loading_overlay.dart        # Loading states
```

### **Utils**
```
lib/utils/store/
├── store_constants.dart            # Store-specific constants
├── price_calculator.dart           # Price calculations
├── cart_helper.dart                # Cart operations
├── validation_helper.dart          # Form validations
└── store_formatters.dart           # Data formatting
```

## 🖥️ **Backend Architecture (Node.js)**

### **Services First** (as requested)
```
services/store/
├── storeService.js                 # Main store business logic
├── productService.js                # Product operations
├── cartService.js                   # Cart management
├── orderService.js                  # Order processing
├── sellerService.js                 # Seller operations
├── categoryService.js               # Category management
├── reviewService.js                 # Review operations
├── paymentService.js               # Payment processing
└── inventoryService.js              # Inventory management
```

### **Controllers**
```
controllers/store/
├── storeController.js               # Main store endpoints
├── productController.js              # Product CRUD operations
├── cartController.js                 # Cart management
├── orderController.js                # Order processing
├── sellerController.js               # Seller operations
├── categoryController.js             # Category management
├── reviewController.js                # Review operations
├── paymentController.js               # Payment endpoints
└── searchController.js                # Search functionality
```

### **Models**
```
models/store/
├── Product.js                       # Product schema
├── Cart.js                          # Cart schema
├── Order.js                         # Order schema
├── Seller.js                        # Seller schema
├── Category.js                      # Category schema
├── Review.js                        # Review schema
├── Payment.js                       # Payment schema
└── Inventory.js                     # Inventory schema
```

### **Middleware**
```
middleware/store/
├── storeAuth.js                     # Store authentication
├── sellerAuth.js                     # Seller verification
├── productValidation.js              # Product validation
├── orderValidation.js                 # Order validation
├── paymentValidation.js               # Payment validation
└── storeRateLimit.js                 # Rate limiting
```

### **Routes**
```
routes/store/
├── storeRoutes.js                   # Main store routes
├── productRoutes.js                 # Product routes
├── cartRoutes.js                    # Cart routes
├── orderRoutes.js                   # Order routes
├── sellerRoutes.js                  # Seller routes
├── categoryRoutes.js               # Category routes
├── reviewRoutes.js                  # Review routes
└── paymentRoutes.js                # Payment routes
```

### **Utils**
```
utils/store/
├── storeConstants.js                # Store constants
├── priceCalculator.js                # Price calculations
├── inventoryManager.js               # Inventory tracking
├── orderProcessor.js                 # Order processing
├── paymentProcessor.js               # Payment handling
└── storeValidators.js                # Validation functions
```

## 🔄 **Database Schema (Supabase)**

### **Store Tables**
```sql
-- Products table
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID REFERENCES users(id),
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  category_id UUID REFERENCES categories(id),
  images TEXT[], -- Array of image URLs
  stock_quantity INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Categories table
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  image_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Cart table
CREATE TABLE cart_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  product_id UUID REFERENCES products(id),
  quantity INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, product_id)
);

-- Orders table
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  seller_id UUID REFERENCES users(id),
  total_amount DECIMAL(10,2) NOT NULL,
  status TEXT DEFAULT 'pending', -- pending, confirmed, shipped, delivered, cancelled
  shipping_address JSONB,
  payment_status TEXT DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Order items table
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id),
  product_id UUID REFERENCES products(id),
  quantity INTEGER NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Reviews table
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  product_id UUID REFERENCES products(id),
  order_id UUID REFERENCES orders(id),
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Sellers table (extends users)
CREATE TABLE sellers (
  id UUID PRIMARY KEY REFERENCES users(id),
  business_name TEXT NOT NULL,
  business_type TEXT, -- individual, business, enterprise
  tax_id TEXT,
  bank_account JSONB,
  is_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);
```

## 🚀 **Implementation Priority**

### **Phase 1: Core Store Services**
1. **Services**: `storeService.js`, `productService.js`
2. **Models**: `Product.js`, `Category.js`
3. **Controllers**: `storeController.js`, `productController.js`
4. **Frontend**: `store_service.dart`, `product_service.dart`

### **Phase 2: Shopping Experience**
1. **Services**: `cartService.js`, `orderService.js`
2. **Models**: `Cart.js`, `Order.js`
3. **Controllers**: `cartController.js`, `orderController.js`
4. **Frontend**: `cart_service.dart`, `order_service.dart`

### **Phase 3: Seller Features**
1. **Services**: `sellerService.js`
2. **Models**: `Seller.js`
3. **Controllers**: `sellerController.js`
4. **Frontend**: `seller_service.dart`

### **Phase 4: Advanced Features**
1. **Services**: `reviewService.js`, `paymentService.js`
2. **Models**: `Review.js`, `Payment.js`
3. **Controllers**: `reviewController.js`, `paymentController.js`
4. **Frontend**: `review_service.dart`, `payment_service.dart`

## 📋 **File Creation Order**

### **Backend First (Services → Models → Controllers)**
```bash
# 1. Create services
mkdir -p services/store
touch services/store/storeService.js
touch services/store/productService.js

# 2. Create models
mkdir -p models/store
touch models/store/Product.js
touch models/store/Category.js

# 3. Create controllers
mkdir -p controllers/store
touch controllers/store/storeController.js
touch controllers/store/productController.js
```

### **Frontend Second (Services → Models → Screens)**
```bash
# 1. Create services
mkdir -p lib/services/store
touch lib/services/store/store_service.dart
touch lib/services/store/product_service.dart

# 2. Create models
mkdir -p lib/models/store
touch lib/models/store/product_model.dart
touch lib/models/store/category_model.dart

# 3. Create screens
mkdir -p lib/screen/store
touch lib/screen/store/store_home_screen.dart
touch lib/screen/store/product_list_screen.dart
```

## 🎯 **Key Benefits of This Architecture**

1. **Services First**: Business logic centralized and reusable
2. **Modular Design**: Each feature has its own folder structure
3. **Scalable**: Easy to add new features without affecting existing code
4. **Maintainable**: Clear separation of concerns
5. **Testable**: Each service can be tested independently
6. **Consistent**: Same pattern for all store-related features

This architecture ensures that any store-related functionality follows the same pattern: **Services → Models → Controllers → Routes → Frontend Services → Frontend Models → Frontend Screens**.
