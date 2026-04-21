package com.sri.agenda.entity;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

/**
 * Sessão de autenticação opaca.
 * Criada no login (POST /api/auth/login), invalidada no logout ou por expiração (8h).
 * O ID é o token opaco retornado ao cliente e enviado em X-Session-Id a cada requisição.
 */
@Entity
@Table(name = "sessao")
public class Sessao extends PanacheEntityBase {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    public UUID id;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "usuario_id", nullable = false)
    public Usuario usuario;

    @Column(name = "criado_em", nullable = false, updatable = false)
    public LocalDateTime criadoEm = LocalDateTime.now();

    @Column(name = "expira_em", nullable = false)
    public LocalDateTime expiraEm = LocalDateTime.now().plusHours(8);

    // -------------------------------------------------------------------------

    /** Busca uma sessão pelo ID somente se ainda não expirou. */
    public static Optional<Sessao> findValid(UUID id) {
        return find("id = ?1 AND expiraEm > ?2", id, LocalDateTime.now())
                .firstResultOptional();
    }
}
