from fastapi import APIRouter
from app.Api.v1.endpoints import AuthEndpoint, AdminEndpoint

api_router = APIRouter()

api_router.include_router(AuthEndpoint.router, prefix="/auth", tags=["Auth"])
api_router.include_router(AdminEndpoint.router, prefix="/admin", tags=["admin"])
