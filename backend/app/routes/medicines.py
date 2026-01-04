from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import Medicine, Pharmacy, Order, OrderItem
from sqlalchemy import or_

medicines_bp = Blueprint('medicines', __name__)


@medicines_bp.route('', methods=['GET'])
def get_medicines():
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    category = request.args.get('category')
    search = request.args.get('search')
    
    query = Medicine.query
    
    if category:
        query = query.filter_by(category=category)
    
    if search:
        query = query.filter(
            or_(
                Medicine.name.ilike(f'%{search}%'),
                Medicine.generic_name.ilike(f'%{search}%')
            )
        )
    
    pagination = query.paginate(page=page, per_page=per_page, error_out=False)
    
    return jsonify({
        'medicines': [m.to_dict() for m in pagination.items],
        'total': pagination.total,
        'pages': pagination.pages
    })


@medicines_bp.route('/categories', methods=['GET'])
def get_categories():
    categories = [
        {'id': 'all', 'name': 'All', 'icon': 'grid_view'},
        {'id': 'antibiotics', 'name': 'Antibiotics', 'icon': 'pill'},
        {'id': 'vitamins', 'name': 'Vitamins', 'icon': 'nutrition'},
        {'id': 'first_aid', 'name': 'First Aid', 'icon': 'medical_services'},
        {'id': 'pain_relief', 'name': 'Pain Relief', 'icon': 'healing'},
    ]
    return jsonify(categories)


@medicines_bp.route('/pharmacies', methods=['GET'])
def get_pharmacies():
    is_open = request.args.get('is_open')
    
    query = Pharmacy.query
    if is_open == 'true':
        query = query.filter_by(is_open=True)
    
    pharmacies = query.order_by(Pharmacy.rating.desc()).all()
    return jsonify([p.to_dict() for p in pharmacies])


@medicines_bp.route('/pharmacies/<int:pharmacy_id>', methods=['GET'])
def get_pharmacy(pharmacy_id):
    pharmacy = Pharmacy.query.get_or_404(pharmacy_id)
    # Return full pharmacy data
    return jsonify({
        'id': pharmacy.id,
        'name': pharmacy.name,
        'address': pharmacy.address,
        'city': pharmacy.city,
        'latitude': float(pharmacy.latitude) if pharmacy.latitude else None,
        'longitude': float(pharmacy.longitude) if pharmacy.longitude else None,
        'phone': pharmacy.phone,
        'rating': float(pharmacy.rating) if pharmacy.rating else None,
        'total_reviews': pharmacy.total_reviews or 0,
        'delivery_time': pharmacy.delivery_time,
        'delivery_fee': float(pharmacy.delivery_fee) if pharmacy.delivery_fee else None,
        'free_delivery_above': float(pharmacy.free_delivery_above) if pharmacy.free_delivery_above else None,
        'is_verified': pharmacy.is_verified,
        'is_open': pharmacy.is_open,
        'image_url': pharmacy.image_url
    })


@medicines_bp.route('/orders', methods=['POST'])
@jwt_required()
def create_order():
    user_id = get_jwt_identity()
    data = request.get_json()
    
    import uuid
    order_number = f"ORD-{uuid.uuid4().hex[:8].upper()}"
    
    order = Order(
        order_number=order_number,
        user_id=user_id,
        pharmacy_id=data.get('pharmacy_id'),
        delivery_address=data.get('delivery_address'),
        subtotal=data.get('subtotal', 0),
        delivery_fee=data.get('delivery_fee', 2.99),
        total_amount=data.get('total_amount'),
        eta_minutes=data.get('eta_minutes', 25),
        prescription_url=data.get('prescription_url')
    )
    
    db.session.add(order)
    db.session.flush()
    
    for item in data.get('items', []):
        order_item = OrderItem(
            order_id=order.id,
            medicine_id=item['medicine_id'],
            quantity=item.get('quantity', 1),
            price=item.get('price', 0)
        )
        db.session.add(order_item)
    
    db.session.commit()
    
    return jsonify({
        'message': 'Order placed successfully',
        'order_number': order_number,
        'eta_minutes': order.eta_minutes
    }), 201


@medicines_bp.route('/orders', methods=['GET'])
@jwt_required()
def get_orders():
    user_id = get_jwt_identity()
    
    orders = Order.query.filter_by(user_id=user_id).order_by(Order.created_at.desc()).all()
    
    result = []
    for o in orders:
        result.append({
            'id': o.id,
            'order_number': o.order_number,
            'status': o.status,
            'total_amount': float(o.total_amount) if o.total_amount else 0,
            'eta_minutes': o.eta_minutes,
            'created_at': o.created_at.isoformat()
        })
    
    return jsonify(result)


@medicines_bp.route('/orders/<int:order_id>/track', methods=['GET'])
@jwt_required()
def track_order(order_id):
    user_id = get_jwt_identity()
    order = Order.query.filter_by(id=order_id, user_id=user_id).first_or_404()
    
    return jsonify({
        'order_number': order.order_number,
        'status': order.status,
        'eta_minutes': order.eta_minutes,
        'progress': 75 if order.status == 'on_the_way' else 50,
        'delivery_address': order.delivery_address
    })
