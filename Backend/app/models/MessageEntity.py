from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.db.base import Base
from sqlalchemy import Index

class Message(Base):
    __tablename__ = "messages"
    __table_args__ = (
        Index('ix_messages_sender_receiver', 'sender_id', 'receiver_id'),
    )

    id = Column(Integer, primary_key=True, index=True)
    sender_id = Column(Integer, ForeignKey("usuarios.id_usuario"), nullable=False)
    receiver_id = Column(Integer, ForeignKey("usuarios.id_usuario"), nullable=False)
    content = Column(String(1000), nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())
    is_read = Column(Boolean, default=False)
    delivered_at = Column(DateTime(timezone=True), nullable=True)
    read_at = Column(DateTime(timezone=True), nullable=True)

    sender = relationship("User", foreign_keys=[sender_id])
    receiver = relationship("User", foreign_keys=[receiver_id])
