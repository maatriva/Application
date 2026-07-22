import 'package:flutter/material.dart';
import '../domain/product.dart';

final List<CategoryItem> initialCategories = [
  const CategoryItem(
    id: 'c1',
    name: 'Accessories',
    icon: Icons.toys_outlined,
    activeColor: Color(0xFF6E3DE0),
    inactiveColor: Color(0xFFF0EBFC),
  ),
  const CategoryItem(
    id: 'c2',
    name: 'Cradle Parts',
    icon: Icons.crib_outlined,
    activeColor: Color(0xFF0E9F6E),
    inactiveColor: Color(0xFFE3F5EE),
  ),
  const CategoryItem(
    id: 'c3',
    name: 'Baby Care',
    icon: Icons.child_care_rounded,
    activeColor: Color(0xFF1866C5),
    inactiveColor: Color(0xFFEBF3FC),
  ),
  const CategoryItem(
    id: 'c4',
    name: 'Feeding',
    icon: Icons.restaurant_menu_rounded,
    activeColor: Color(0xFFE05206),
    inactiveColor: Color(0xFFFCEFE9),
  ),
  const CategoryItem(
    id: 'c5',
    name: 'Toys',
    icon: Icons.videogame_asset_outlined,
    activeColor: Color(0xFFD61F69),
    inactiveColor: Color(0xFFFCE8F0),
  ),
  const CategoryItem(
    id: 'c6',
    name: 'Health',
    icon: Icons.health_and_safety_outlined,
    activeColor: Color(0xFFC2185B),
    inactiveColor: Color(0xFFFCE4EC),
  ),
  const CategoryItem(
    id: 'c7',
    name: 'Clothing',
    icon: Icons.checkroom_outlined,
    activeColor: Color(0xFFB45309),
    inactiveColor: Color(0xFFFEF3C7),
  ),
  const CategoryItem(
    id: 'c8',
    name: 'Smart Devices',
    icon: Icons.smart_toy_outlined,
    activeColor: Color(0xFF1E1B4B),
    inactiveColor: Color(0xFFEEF2F6),
  ),
];

final List<Product> initialMockProducts = [
  const Product(
    id: 'p1',
    name: 'Organic Cotton Sleep Set',
    description:
        'Ultra-soft, organic, and beautifully crafted sleep set made with certified organic cotton. Features dual zipper functionality for convenient night changes and safe seams.',
    category: 'Clothing',
    imageUrl:
        'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&w=600&q=80',
    price: 45.00,
    rating: 4.8,
    reviewsCount: 150,
    isNewArrival: true,
    isFeatured: true,
    features: [
      '100% GOTS certified organic cotton',
      'Two-way smooth safety zipper',
      'Hypoallergenic material for extra-sensitive baby skin',
    ],
    specifications: {
      'Material': '100% Organic Cotton',
      'Size range': '0 - 12 months',
      'Machine Wash': 'Yes',
    },
    reviews: [
      ProductReview(
        reviewerName: 'Rebecca L.',
        rating: 5.0,
        comment: 'So soft and holds up perfectly in the wash!',
        date: 'June 14, 2026',
      ),
      ProductReview(
        reviewerName: 'Marcus T.',
        rating: 4.5,
        comment: 'Great fit and cute colors. Highly recommend.',
        date: 'July 1, 2026',
      ),
    ],
  ),
  const Product(
    id: 'p2',
    name: 'Soft Touch Pacifier',
    description:
        'Medical-grade orthodontic silicone pacifier designed carefully to mimic maternal soothing patterns. It promotes healthy dental and gums development.',
    category: 'Baby Care',
    imageUrl:
        'https://images.unsplash.com/photo-1596464716127-f2a82984de30?auto=format&fit=crop&w=600&q=80',
    price: 12.00,
    rating: 4.9,
    reviewsCount: 120,
    isNewArrival: false,
    isFeatured: true,
    features: [
      'BPA-free orthodontic shield',
      'Shield ventilation openings prevent skin irritation',
      'Sterilizer-safe components',
    ],
    specifications: {
      'Material': '100% Medical-grade Silicone',
      'BPA Free': 'Yes',
      'Items in Pack': '2 pack',
    },
    reviews: [
      ProductReview(
        reviewerName: 'Sarah K.',
        rating: 5.0,
        comment: 'The only pacifier my newborn will accept. Saved us!',
        date: 'May 20, 2026',
      ),
    ],
  ),
  const Product(
    id: 'p3',
    name: 'Bamboo Knit Blanket',
    description:
        'Naturally breathable swaddling knit blanket derived from organic bamboo fibers. Gently regulates infants body temperature to keep them cosy.',
    category: 'Baby Care',
    imageUrl:
        'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=600&q=80',
    price: 38.00,
    rating: 4.8,
    reviewsCount: 85,
    isNewArrival: false,
    isFeatured: false,
    features: [
      'Naturally hypoallergenic & antimicrobial',
      'Four-way stretch flexible weave',
      'Thermal-regulating micro fibers',
    ],
    specifications: {
      'Material': '70% Bamboo Silk, 30% Egyptian Cotton',
      'Dimensions': '44" x 44"',
      'Hypoallergenic': 'Yes',
    },
    reviews: [
      ProductReview(
        reviewerName: 'James D.',
        rating: 4.8,
        comment: 'Unbelievably soft blanket. Worth every single penny!',
        date: 'April 22, 2026',
      ),
    ],
  ),
  const Product(
    id: 'p4',
    name: 'Silent Glide Cradle Wheels',
    description:
        'Noiseless premium ball bearing wheels designed specifically to glide on hardwood or carpets with absolute zero vibration.',
    category: 'Cradle Parts',
    imageUrl:
        'https://images.unsplash.com/photo-1591088398332-8a7791972843?auto=format&fit=crop&w=600&q=80',
    price: 24.00,
    rating: 5.0,
    reviewsCount: 42,
    isNewArrival: true,
    isFeatured: false,
    features: [
      'Super quiet dual ball bearing glide',
      'Non-scratching elastomer shell wheels',
      'Single-foot secure safety locking locks',
    ],
    specifications: {
      'Stem Size': 'M8 Threaded',
      'Max Load': '120 lbs (Set of 4)',
      'Brakes': 'Yes, dual locking',
    },
    reviews: [
      ProductReview(
        reviewerName: 'Michael P.',
        rating: 5.0,
        comment: 'These wheels are completely silent. Excellent upgrade!',
        date: 'March 11, 2026',
      ),
    ],
  ),
  const Product(
    id: 'p5',
    name: 'Wireless Baby Monitor',
    description:
        'High definition 1080p baby camera with automatic infrared night vision, integrated temperature & sound sensors, and crystal clear two-way communication talk-back.',
    category: 'Smart Devices',
    imageUrl:
        'https://images.unsplash.com/photo-1558002038-1055907df827?auto=format&fit=crop&w=600&q=80',
    price: 149.00,
    rating: 4.9,
    reviewsCount: 310,
    isNewArrival: false,
    isFeatured: true,
    features: [
      'Encrypted private FHSS 2.4GHz transmission',
      'Remote pan, tilt, and 4x smart zoom',
      'Room climate tracking alerts',
    ],
    specifications: {
      'Range': 'Up to 900 feet',
      'Screen Size': '5 inch LCD Receiver',
      'Battery Life': '15 hours audio-only',
      'Power Source': 'Battery or AC plug',
    },
    reviews: [
      ProductReview(
        reviewerName: 'Elena V.',
        rating: 5.0,
        comment:
            'Signal is incredibly strong, and video is high definition even in total darkness!',
        date: 'January 19, 2026',
      ),
    ],
  ),
  const Product(
    id: 'p6',
    name: 'Digital Thermometer',
    description:
        'Non-contact hospital-grade medical infrared thermometer with instant read indicators. Color-coded fever warnings on back-lit LCD screen.',
    category: 'Health',
    imageUrl:
        'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=600&q=80',
    price: 32.00,
    rating: 4.7,
    reviewsCount: 95,
    isNewArrival: false,
    isFeatured: false,
    features: [
      'One-second contact-free temperature checking',
      'Stores last 32 readings in database',
      'Fever warning beep and color indicator',
    ],
    specifications: {
      'Accuracy': '±0.2 degrees C',
      'Distance': '1 - 5 cm optimal',
      'Battery': '2x AAA (Included)',
    },
    reviews: [
      ProductReview(
        reviewerName: 'Diana S.',
        rating: 4.5,
        comment: 'Easy to check babys temp without waking them up.',
        date: 'May 3, 2026',
      ),
    ],
  ),
  const Product(
    id: 'p7',
    name: 'Bottle Sterilizer',
    description:
        'Steam-powered smart high-capacity sterilizer kills 99.9% of bacteria. Complete cycle with integrated fan-drying in just 45 minutes.',
    category: 'Feeding',
    imageUrl:
        'https://images.unsplash.com/photo-1588854337236-6889d631faa8?auto=format&fit=crop&w=600&q=80',
    price: 69.00,
    rating: 4.8,
    reviewsCount: 142,
    isNewArrival: true,
    isFeatured: false,
    features: [
      'High-velocity hot steam disinfection',
      'Holds up to 6 wide neck bottles plus accessories',
      'HEPA filter for sterile air drying',
    ],
    specifications: {
      'Time': 'Sterilize 10m + Dry 35m',
      'Material': 'BPA-free food safe PP',
      'Power Source': '120V AC plug',
    },
  ),
  const Product(
    id: 'p8',
    name: 'Smart Sleep Sensor',
    description:
        'Ultra-light respiratory and sleeping pattern sensor. Clips safely to baby clothes to provide instant, non-intrusive monitoring.',
    category: 'Smart Devices',
    imageUrl:
        'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=600&q=80',
    price: 119.00,
    rating: 4.6,
    reviewsCount: 68,
    isNewArrival: false,
    isFeatured: true,
    features: [
      'Monitors roll-over & breathing activity',
      'Radiation-free ultra low energy Bluetooth',
      'Washable silicone protective skin',
    ],
    specifications: {
      'Sensor Weight': '9.5 grams',
      'Waterproof': 'IP67 rated',
      'Battery Life': '7 days rechargeable',
    },
  ),
  const Product(
    id: 'p9',
    name: 'Calming Baby Lotion',
    description:
        'Moisturizes skin with continuous organic hydration while soothing baby senses for bed. Formulated with chamomile and lavender extracts.',
    category: 'Baby Care',
    imageUrl:
        'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=600&q=80',
    price: 18.50,
    rating: 4.7,
    reviewsCount: 210,
    isNewArrival: false,
    isFeatured: false,
    features: [
      'Infused with 100% natural lavender oil',
      'Dermatologist tested & pediatrician approved',
      'Free from parabens, phthalates, or dyes',
    ],
    specifications: {
      'Volume': '250 ml (8.4 fl oz)',
      'Ph balanced': 'Yes',
      'Fragrance': 'Natural Lavender Chamomile',
    },
  ),
];
