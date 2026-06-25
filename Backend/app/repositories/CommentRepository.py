from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from app.models.CommentEntity import Comment


def get_comments(db: Session, skip: int = 0, limit: int = 100) -> list[Comment]:
    return db.query(Comment).offset(skip).limit(limit).all()


def get_comment_by_id(db: Session, id_comentario: int) -> Comment | None:
    return db.query(Comment).filter(Comment.id_comentario == id_comentario).first()


def get_comments_by_user(db: Session, id_usuario: int) -> list[Comment]:
    return db.query(Comment).filter(Comment.id_usuario == id_usuario).all()


def create_comment(db: Session, comment: Comment) -> Comment:
    try:
        db.add(comment)
        db.commit()
        db.refresh(comment)
        return comment
    except IntegrityError:
        db.rollback()
        raise


def update_comment(db: Session, db_comment: Comment, update_data: dict) -> Comment:
    for key, value in update_data.items():
        setattr(db_comment, key, value)

    try:
        db.commit()
        db.refresh(db_comment)
        return db_comment
    except IntegrityError:
        db.rollback()
        raise


def delete_comment(db: Session, db_comment: Comment) -> None:
    db.delete(db_comment)
    db.commit()
