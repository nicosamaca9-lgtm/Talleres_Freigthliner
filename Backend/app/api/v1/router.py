from fastapi import APIRouter
from app.api.v1.endpoints import (
    AuthEndpoint,
    AdminEndpoint,
    VehicleEndpoint,
    TechnicalReportEndpoint,
)
from app.api.v1.endpoints.BookingEndpoint import router as booking_router
from app.api.v1.endpoints.ServiceOrderEndpoint import router as service_order_router

api_router = APIRouter()

api_router.include_router(AuthEndpoint.router, prefix="/auth", tags=["Auth"])
api_router.include_router(AdminEndpoint.router, prefix="/admin", tags=["admin"])
api_router.include_router(VehicleEndpoint.router, prefix="/vehicles", tags=["Vehicles"])
api_router.include_router(booking_router, prefix="/bookings", tags=["Bookings"])
api_router.include_router(
    service_order_router, prefix="/service-orders", tags=["Service Orders"]
)
api_router.include_router(
    TechnicalReportEndpoint.router,
    prefix="/technical-reports",
    tags=["Technical Reports"],
)
