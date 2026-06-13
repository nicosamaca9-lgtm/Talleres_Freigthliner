from sqlalchemy.orm import Session
from app.models.UserEntity import User


def get_user_by_email(db: Session, correo: str) -> User | None:
    return db.query(User).filter(User.correo == correo).first()


from sqlalchemy import or_

def get_user_by_email_or_phone(db: Session, correo: str, telefono: str | None) -> User | None:
    filters = [User.correo == correo]
    if telefono:
        filters.append(User.telefono == telefono)
    return db.query(User).filter(or_(*filters)).first()


def get_user_by_id(db: Session, id_usuario: int) -> User | None:
    return db.query(User).filter(User.id_usuario == id_usuario).first()


from sqlalchemy.exc import IntegrityError

def create_user(db: Session, user: User) -> User:
    try:
        db.add(user)
        db.commit()
        db.refresh(user)
        return user
    except IntegrityError:
        db.rollback()
        raise
