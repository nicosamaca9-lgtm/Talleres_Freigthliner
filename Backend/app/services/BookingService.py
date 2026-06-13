from sqlalchemy.orm import Session
from app.models.BookingEntity import Booking
from app.schemas.BookingSchema import BookingCreate

class BookingService:

    @staticmethod
    def create_booking(db: Session, booking_data: BookingCreate):
        """Crea un nuevo agendamiento en la base de datos"""
        db_booking = Booking(**booking_data.model_dump())
        db.add(db_booking)
        db.commit()
        db.refresh(db_booking)
        return db_booking

    @staticmethod
    def get_all_bookings(db: Session, skip: int = 0, limit: int = 100):
        """Lista todos los agendamientos registrados"""
        return db.query(Booking).offset(skip).limit(limit).all()

    @staticmethod
    def get_bookings_by_vehicle(db: Session, id_vehiculo: int):
        """Busca agendamientos asociados a un vehículo específico"""
        return db.query(Booking).filter(Booking.id_vehiculo == id_vehiculo).all()