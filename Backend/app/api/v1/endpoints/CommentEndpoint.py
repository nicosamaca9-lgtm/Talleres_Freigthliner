from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from typing import List

from app.api.deps import get_db
from app.schemas.CommentSchema import CommentRegister, CommentUpdate, CommentResponse
from app.services import CommentService

router = APIRouter()

@router.get("/", response_model=List[CommentResponse], status_code=status.HTTP_200_OK)
def read_comments(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """
    Retrieve comments.
    """
    return CommentService.get_all_comments(db, skip=skip, limit=limit)


@router.get("/{id_comentario}", response_model=CommentResponse, status_code=status.HTTP_200_OK)
def read_comment(id_comentario: int, db: Session = Depends(get_db)):
    """
    Get comment by ID.
    """
    return CommentService.get_comment(db, id_comentario=id_comentario)


@router.post("/", response_model=CommentResponse, status_code=status.HTTP_201_CREATED)
def create_comment(comment_in: CommentRegister, db: Session = Depends(get_db)):
    """
    Create new comment.
    """
    return CommentService.create_comment(db, comment_in=comment_in)


@router.patch("/{id_comentario}", response_model=CommentResponse, status_code=status.HTTP_200_OK)
def update_comment(id_comentario: int, comment_in: CommentUpdate, db: Session = Depends(get_db)):
    """
    Update a comment.
    """
    return CommentService.update_comment(db, id_comentario=id_comentario, comment_in=comment_in)


@router.delete("/{id_comentario}", status_code=status.HTTP_200_OK)
def delete_comment(id_comentario: int, db: Session = Depends(get_db)):
    """
    Delete a comment.
    """
    return CommentService.delete_comment(db, id_comentario=id_comentario)
