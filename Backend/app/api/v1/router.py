from fastapi import APIRouter
from app.api.v1.endpoints import AuthEndpoint, AdminEndpoint, VehicleEndpoint
from app.api.v1.endpoints.BookingEndpoint import router as booking_router

api_router = APIRouter()

api_router.include_router(AuthEndpoint.router, prefix="/auth", tags=["Auth"])
api_router.include_router(AdminEndpoint.router, prefix="/admin", tags=["admin"])
api_router.include_router(VehicleEndpoint.router, prefix="/vehicles", tags=["Vehicles"])
api_router.include_router(booking_router, prefix="/bookings", tags=["Bookings"])