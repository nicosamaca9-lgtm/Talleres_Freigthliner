# app/models/CommentEntity.py

from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import validates, relationship

from app.db.base import Base


class Comment(Base):
    __tablename__ = "calificacion"

    id_comentario = Column(Integer, primary_key=True, index=True)
    id_usuario = Column(Integer, ForeignKey("usuarios.id_usuario"), nullable=False)
    rating = Column(Integer, nullable=False)
    comentario = Column(String(500), nullable=False)
    fecha_registro = Column(DateTime(timezone=True), server_default=func.now())

    usuario = relationship("User", backref="comentarios")

    @validates("rating")
    def validate_rating(self, key, value):
        if not (1 <= value <= 5):
            raise ValueError("La calificación debe estar entre 1 y 5")
        return value
