from fastapi import APIRouter
from app.Api.v1.endpoints import AuthEndpoint, AdminEndpoint, VehicleEndpoint

api_router = APIRouter()

api_router.include_router(AuthEndpoint.router, prefix="/auth", tags=["Auth"])
api_router.include_router(AdminEndpoint.router, prefix="/admin", tags=["admin"])
api_router.include_router(VehicleEndpoint.router, prefix="/vehicles", tags=["Vehicles"])