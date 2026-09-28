package com.ong.acolhepatinhas.api.post;

import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PostRepository extends JpaRepository<Post, Integer> {

    @Override
    @EntityGraph(attributePaths = {"user"})
    Page<Post> findAll(Pageable pageable);

    @EntityGraph(attributePaths = {"user"})
    Optional<Post> findById(int id);
}