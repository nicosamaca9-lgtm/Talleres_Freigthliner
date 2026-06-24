from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.repositories import CommentRepository, UserRepository
from app.schemas.CommentSchema import CommentRegister, CommentUpdate
from app.models.CommentEntity import Comment


def get_all_comments(db: Session, skip: int = 0, limit: int = 100):
    return CommentRepository.get_comments(db, skip=skip, limit=limit)


def get_comment(db: Session, id_comentario: int):
    comment = CommentRepository.get_comment_by_id(db, id_comentario=id_comentario)
    if not comment:
        raise HTTPException(status_code=404, detail="Comentario no encontrado")
    return comment


def create_comment(db: Session, comment_in: CommentRegister):
    # Verify user exists
    user = UserRepository.get_user_by_id(db, id_usuario=comment_in.id_usuario)
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
        
    try:
        new_comment = Comment(
            id_usuario=comment_in.id_usuario,
            rating=comment_in.rating,
            comentario=comment_in.comentario
        )
        return CommentRepository.create_comment(db, comment=new_comment)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail="Error al crear el comentario")


def update_comment(db: Session, id_comentario: int, comment_in: CommentUpdate):
    db_comment = get_comment(db, id_comentario)
    
    update_data = comment_in.model_dump(exclude_unset=True)
    if not update_data:
        raise HTTPException(status_code=400, detail="No se enviaron datos para actualizar")
        
    try:
        # Si se actualiza el rating, la validación se dispara en SQLAlchemy gracias al @validates
        return CommentRepository.update_comment(db, db_comment=db_comment, update_data=update_data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail="Error al actualizar el comentario")


def delete_comment(db: Session, id_comentario: int):
    db_comment = get_comment(db, id_comentario)
    CommentRepository.delete_comment(db, db_comment=db_comment)
    return {"message": "Comentario eliminado exitosamente"}
