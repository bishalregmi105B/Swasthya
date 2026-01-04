from datetime import datetime
from app import db


class Medicine(db.Model):
    __tablename__ = 'medicines'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    generic_name = db.Column(db.String(255))
    category = db.Column(db.String(100))
    form = db.Column(db.String(50))
    strength = db.Column(db.String(50))
    unit = db.Column(db.String(20))
    price = db.Column(db.Numeric(10, 2))
    image_url = db.Column(db.Text)
    description = db.Column(db.Text)
    manufacturer = db.Column(db.String(255))
    is_fda_approved = db.Column(db.Boolean, default=False)
    requires_prescription = db.Column(db.Boolean, default=False)
    rating = db.Column(db.Numeric(3, 2))
    stock = db.Column(db.Integer, default=100)
    pharmacy_id = db.Column(db.Integer, db.ForeignKey('pharmacies.id'))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationship
    pharmacy = db.relationship('Pharmacy', backref='medicines')
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'generic_name': self.generic_name,
            'category': self.category,
            'form': self.form,
            'strength': self.strength,
            'price': float(self.price) if self.price else None,
            'image_url': self.image_url,
            'description': self.description,
            'manufacturer': self.manufacturer,
            'is_fda_approved': self.is_fda_approved,
            'requires_prescription': self.requires_prescription,
            'rating': float(self.rating) if self.rating else None,
            'stock': self.stock,
            'pharmacy_id': self.pharmacy_id,
            'pharmacy_name': self.pharmacy.name if self.pharmacy else None
        }


class Pharmacy(db.Model):
    __tablename__ = 'pharmacies'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    address = db.Column(db.Text)
    city = db.Column(db.String(100))
    latitude = db.Column(db.Numeric(10, 8))
    longitude = db.Column(db.Numeric(11, 8))
    phone = db.Column(db.String(20))
    rating = db.Column(db.Numeric(3, 2))
    total_reviews = db.Column(db.Integer, default=0)
    delivery_time = db.Column(db.String(50))
    delivery_fee = db.Column(db.Numeric(10, 2))
    free_delivery_above = db.Column(db.Numeric(10, 2))
    is_verified = db.Column(db.Boolean, default=False)
    is_open = db.Column(db.Boolean, default=True)
    image_url = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'address': self.address,
            'city': self.city,
            'phone': self.phone,
            'rating': float(self.rating) if self.rating else None,
            'delivery_time': self.delivery_time,
            'is_verified': self.is_verified,
            'is_open': self.is_open
        }


class Order(db.Model):
    __tablename__ = 'orders'
    
    id = db.Column(db.Integer, primary_key=True)
    order_number = db.Column(db.String(50), unique=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    pharmacy_id = db.Column(db.Integer, db.ForeignKey('pharmacies.id'))
    status = db.Column(db.Enum('pending', 'confirmed', 'preparing', 'on_the_way', 'delivered', 'cancelled'), default='pending')
    delivery_address = db.Column(db.Text)
    subtotal = db.Column(db.Numeric(10, 2))
    delivery_fee = db.Column(db.Numeric(10, 2))
    total_amount = db.Column(db.Numeric(10, 2))
    eta_minutes = db.Column(db.Integer)
    prescription_url = db.Column(db.Text)
    notes = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    delivered_at = db.Column(db.DateTime)
    
    items = db.relationship('OrderItem', backref='order')
    user = db.relationship('User')
    pharmacy = db.relationship('Pharmacy')


class OrderItem(db.Model):
    __tablename__ = 'order_items'
    
    id = db.Column(db.Integer, primary_key=True)
    order_id = db.Column(db.Integer, db.ForeignKey('orders.id'), nullable=False)
    medicine_id = db.Column(db.Integer, db.ForeignKey('medicines.id'), nullable=False)
    quantity = db.Column(db.Integer, default=1)
    price = db.Column(db.Numeric(10, 2))
    
    medicine = db.relationship('Medicine')
