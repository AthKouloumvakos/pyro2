!xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
subroutine trans_vels(qx, qy, ng, dx, dy, dt, &
                      u, v, &
                      ldelta_ux, ldelta_vy, &
                      utrans, vtrans)

  implicit none

  integer, intent(in) :: qx, qy, ng
  double precision, intent(in) :: dx, dy, dt

  ! 0-based indexing to match python
  double precision, intent(inout) :: u(0:qx-1, 0:qy-1)
  double precision, intent(inout) :: v(0:qx-1, 0:qy-1)

  double precision, intent(inout) :: ldelta_ux(0:qx-1, 0:qy-1)
  double precision, intent(inout) :: ldelta_vy(0:qx-1, 0:qy-1)

  double precision, intent(  out) :: utrans(0:qx-1, 0:qy-1)
  double precision, intent(  out) :: vtrans(0:qx-1, 0:qy-1)

!f2py depend(qx, qy) :: u, v, ldelta_ux, ldelta_vy
!f2py depend(qx, qy) :: utrans, vtrans
!f2py intent(in) :: u, v, ldelta_ux, ldelta_vy
!f2py intent(out) :: utrans, vtrans
 
  ! construct the transverse states of u and v --- these will be
  ! used in constructing the transverse flux difference for the 
  ! full interface states

  ! specifically, we need u on the x-interfaces (for the transverse
  ! term in the v normal state) and v on the y-interfaces (for the
  ! transverse term in the u normal state)

  integer :: ilo, ihi, jlo, jhi
  integer :: nx, ny
  integer :: i, j

  double precision :: q_l(0:qx-1, 0:qy-1), q_r(0:qx-1, 0:qy-1)
  

  nx = qx - 2*ng; ny = qy - 2*ng
  ilo = ng; ihi = ng+nx-1; jlo = ng; jhi = ng+ny-1


  ! x-interface states of u
  dtdx = dt/dx

  do j = jlo-2, jhi+2
     do i = ilo-2, ihi+2
        
        q_l(i+1,j) = u(i,j) + 0.5d0*(1.0d0 - dtdx*u(i,j))*ldelta_ux(i,j)
        q_r(i  ,j) = u(i,j) - 0.5d0*(1.0d0 + dtdx*u(i,j))*ldelta_ux(i,j)

     enddo
  enddo

  ! Riemann problem -- this is based on Burger's equation.  See 
  ! Bell, Colella, and Howell (1991), Eq. 3.3, or Almgren, Bell,
  ! and Szymczak (1996) (top of page 362)
  do j = jlo-1, jhi+1
     do i = ilo-1, ihi+1
        if (q_l(i,j) > 0.0d0 .and. (q_l(i,j) + q_r(i,j)) > 0.0d0) then
           utrans(i,j) = q_l(i,j)
        else if (q_l(i,j) <= 0.0d0 .and. q_r(i,j) >= 0.0d0) then
           utrans(i,j) = 0.0d0
        else
           utrans(i,j) = q_r(i,j)
        endif
     enddo
  enddo


  ! y-interface states of v
  dtdy = dt/dy

  do j = jlo-2, jhi+2
     do i = ilo-2, ihi+2
        
        q_l(i,j+1) = v(i,j) + 0.5d0*(1.0d0 - dtdy*v(i,j))*ldelta_vy(i,j)
        q_r(i,j  ) = v(i,j) - 0.5d0*(1.0d0 + dtdy*v(i,j))*ldelta_vy(i,j)

     enddo
  enddo

  ! Riemann problem for Burger's equation
  do j = jlo-1, jhi+1
     do i = ilo-1, ihi+1
        if (q_l(i,j) > 0.0d0 .and. (q_l(i,j) + q_r(i,j)) > 0.0d0) then
           vtrans(i,j) = q_l(i,j)
        else if (q_l(i,j) <= 0.0d0 .and. q_r(i,j) >= 0.0d0) then
           vtrans(i,j) = 0.0d0
        else
           vtrans(i,j) = q_r(i,j)
        endif
     enddo
  enddo

end subroutine trans_vels


!xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
subroutine mac_vels(qx, qy, ng, dx, dy, dt, &
                    u, v, &
                    ldelta_ux, ldelta_vx, &
                    ldelta_uy, ldelta_vy, &
                    gradp_x, gradp_y, &
                    utrans, vtrans, &
                    u_MAC, v_MAC)

  implicit none

  integer, intent(in) :: qx, qy, ng
  double precision, intent(in) :: dx, dy, dt

  ! 0-based indexing to match python
  double precision, intent(inout) :: u(0:qx-1, 0:qy-1)
  double precision, intent(inout) :: v(0:qx-1, 0:qy-1)

  double precision, intent(inout) :: ldelta_ux(0:qx-1, 0:qy-1)
  double precision, intent(inout) :: ldelta_vx(0:qx-1, 0:qy-1)

  double precision, intent(inout) :: ldelta_uy(0:qx-1, 0:qy-1)
  double precision, intent(inout) :: ldelta_vy(0:qx-1, 0:qy-1)

  double precision, intent(inout) :: gradp_x(0:qx-1, 0:qy-1)
  double precision, intent(inout) :: gradp_y(0:qx-1, 0:qy-1)

  double precision, intent(inout) :: utrans(0:qx-1, 0:qy-1)
  double precision, intent(inout) :: vtrans(0:qx-1, 0:qy-1)

  double precision, intent(  out) :: u_MAC(0:qx-1, 0:qy-1)
  double precision, intent(  out) :: v_MAC(0:qx-1, 0:qy-1)

!f2py depend(qx, qy) :: u, v
!f2py depend(qx, qy) :: ldelta_ux, ldelta_vx, ldelta_uy, ldelta_vy
!f2py depend(qx, qy) :: gradp_x, gradp_y
!f2py depend(qx, qy) :: utrans, vtrans
!f2py depend(qx, qy) :: u_MAC, v_MAC
!f2py intent(in) :: u, v, gradp_x, gradp_y, utrans, vtrans
!f2py intent(in) :: ldelta_ux, ldelta_vx, ldelta_uy, ldelta_vy
!f2py intent(out) :: u_MAC, v_MAC

  integer :: ilo, ihi, jlo, jhi
  integer :: nx, ny
  integer :: i, j

  double precision :: u_xl(0:qx-1, 0:qy-1), u_xr(0:qx-1, 0:qy-1)
  double precision :: u_yl(0:qx-1, 0:qy-1), u_yr(0:qx-1, 0:qy-1)
  double precision :: v_xl(0:qx-1, 0:qy-1), v_xr(0:qx-1, 0:qy-1)
  double precision :: v_yl(0:qx-1, 0:qy-1), v_yr(0:qx-1, 0:qy-1)

  double precision :: u_xint(0:qx-1, 0:qy-1), u_yint(0:qx-1, 0:qy-1)  
  double precision :: v_xint(0:qx-1, 0:qy-1), v_yint(0:qx-1, 0:qy-1)  

  nx = qx - 2*ng; ny = qy - 2*ng
  ilo = ng; ihi = ng+nx-1; jlo = ng; jhi = ng+ny-1
  
  ! u on x-edges
  dtdx = dt/dx

  do j = jlo-2, jhi+2
     do i = ilo-2, ihi+2        
        u_xl(i+1,j) = u(i,j) + 0.5d0*(1.0d0 - dtdx*u(i,j))*ldelta_ux(i,j)
        u_xr(i  ,j) = u(i,j) - 0.5d0*(1.0d0 + dtdx*u(i,j))*ldelta_ux(i,j)
     enddo
  enddo

  ! Riemann problem -- use utrans for the upwinding velocity.  The resulting
  ! quantity, u_xint, is what is used in the transverse difference
  call upwind(qx, qy, ng, &
              u_xl, u_xr, &
              utrans, &
              u_xint)


  ! v on x-edges -- needed for the transverse term
  do j = jlo-2, jhi+2
     do i = ilo-2, ihi+2        
        v_xl(i+1,j) = v(i,j) + 0.5d0*(1.0d0 - dtdx*u(i,j))*ldelta_vx(i,j)
        v_xr(i  ,j) = v(i,j) - 0.5d0*(1.0d0 + dtdx*u(i,j))*ldelta_vx(i,j)
     enddo
  enddo

  ! Riemann problem -- use utrans for the upwinding velocity.  The resulting
  ! quantity, u_xint, is what is used in the transverse difference
  call upwind(qx, qy, ng, &
              v_xl, v_xr, &
              utrans, &
              v_xint)


  ! u on y-edges -- needed for the transverse term
  dtdy = dt/dy

  do j = jlo-2, jhi+2
     do i = ilo-2, ihi+2        
        u_yl(i,j+1) = u(i,j) + 0.5d0*(1.0d0 - dtdy*v(i,j))*ldelta_uy(i,j)
        u_yr(i,j  ) = u(i,j) - 0.5d0*(1.0d0 + dtdy*v(i,j))*ldelta_uy(i,j)
     enddo
  enddo

  ! Riemann problem -- use vtrans for the upwinding velocity.  The resulting
  ! quantity, v_yint, is what is used in the transverse difference
  call upwind(qx, qy, ng, &
              u_yl, u_yr, &
              vtrans, &
              u_yint)


  ! v on y-edges
  do j = jlo-2, jhi+2
     do i = ilo-2, ihi+2        
        v_yl(i,j+1) = v(i,j) + 0.5d0*(1.0d0 - dtdy*v(i,j))*ldelta_vy(i,j)
        v_yr(i,j  ) = v(i,j) - 0.5d0*(1.0d0 + dtdy*v(i,j))*ldelta_vy(i,j)
     enddo
  enddo
  
  ! Riemann problem -- use vtrans for the upwinding velocity.  The resulting
  ! quantity, v_yint, is what is used in the transverse difference
  call upwind(qx, qy, ng, &
              v_yl, v_yr, &
              vtrans, &
              v_yint)


  ! add the transverse flux differences to the preliminary interface states
  do j = jlo-2, jhi+2
     do i = ilo-2, ihi+2        

        ! v du/dy is the transverse term for the u normal states
        vbar = 0.5d0*(vtrans(i,j) + vtrans(i,j+1))
        vu_y = vbar*(u_yint(i,j+1) - u_yint(i,j))
        
        u_xl(i+1,j) = u_xl(i+1,j) - 0.5*dtdy*vu_y - 0.5*dt*gradp_x(i,j)
        u_xr(i  ,j) = u_xr(i  ,j) - 0.5*dtdy*vu_y - 0.5*dt*gradp_x(i,j)

        ! u dv/dx is the transverse term for the v normal states
        ubar = 0.5d0*(utrans(i,j) + utrans(i+1,j)
        uv_x = ubar*(v_xint(i+1,j) - v_xint(i,j))

        v_yl(i,j+1) = v_yl(i,j+1) - 0.5*dtdx*uv_x - 0.5*dt*gradp_y(i,j)
        v_yr(i,j  ) = v_yr(i,j  ) - 0.5*dtdx*uv_x - 0.5*dt*gradp_y(i,j)

     enddo
  enddo


  ! Riemann problem -- this follows Burger's equation.  We don't use
  ! any input velocity for the upwinding.
  
  ! we only need u on x faces and v on y faces
  call riemann_and_upwind(qx, qy, ng, &
                          u_xl, u_xr, &
                          u_MAC)

  call riemann_and_upwind(qx, qy, ng, &
                          v_yl, v_yr, &
                          v_MAC)
    
end subroutine mac_vels


!xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
subroutine states(qx, qy, ng, dx, dy, dt, &
                  u, v, &
                  ldelta_ux, ldelta_vx, &
                  ldelta_uy, ldelta_vy, &
                  gradp_x, gradp_y, &
                  utrans, vtrans, &
                  u_MAC, v_MAC, &
                  u_xint, v_xint, u_yint, v_yint)

  ! this is similar to mac_vels, but it predicts the interface states
  ! of both u and v on both interfaces, using the MAC velocities to
  ! do the upwinding.

  implicit none

  integer, intent(in) :: qx, qy, ng
  double precision, intent(in) :: dx, dy, dt

  ! 0-based indexing to match python
  double precision, intent(inout) :: u(0:qx-1, 0:qy-1)
  double precision, intent(inout) :: v(0:qx-1, 0:qy-1)

  double precision, intent(inout) :: ldelta_ux(0:qx-1, 0:qy-1)
  double precision, intent(inout) :: ldelta_vx(0:qx-1, 0:qy-1)

  double precision, intent(inout) :: ldelta_uy(0:qx-1, 0:qy-1)
  double precision, intent(inout) :: ldelta_vy(0:qx-1, 0:qy-1)

  double precision, intent(inout) :: gradp_x(0:qx-1, 0:qy-1)
  double precision, intent(inout) :: gradp_y(0:qx-1, 0:qy-1)

  double precision, intent(inout) :: utrans(0:qx-1, 0:qy-1)
  double precision, intent(inout) :: vtrans(0:qx-1, 0:qy-1)

  double precision, intent(inout) :: u_MAC(0:qx-1, 0:qy-1)
  double precision, intent(inout) :: v_MAC(0:qx-1, 0:qy-1)

  double precision, intent(out) :: u_xint(0:qx-1, 0:qy-1), u_yint(0:qx-1, 0:qy-1)  
  double precision, intent(out) :: v_xint(0:qx-1, 0:qy-1), v_yint(0:qx-1, 0:qy-1)  

!f2py depend(qx, qy) :: u, v
!f2py depend(qx, qy) :: ldelta_ux, ldelta_vx, ldelta_uy, ldelta_vy
!f2py depend(qx, qy) :: gradp_x, gradp_y
!f2py depend(qx, qy) :: utrans, vtrans
!f2py depend(qx, qy) :: u_MAC, v_MAC
!f2py intent(in) :: u, v, gradp_x, gradp_y, utrans, vtrans
!f2py intent(in) :: ldelta_ux, ldelta_vx, ldelta_uy, ldelta_vy
!f2py intent(in) :: u_MAC, v_MAC
!f2py intent(out) :: u_xint, v_xint, u_yint, v_yint

  integer :: ilo, ihi, jlo, jhi
  integer :: nx, ny
  integer :: i, j

  double precision :: u_xl(0:qx-1, 0:qy-1), u_xr(0:qx-1, 0:qy-1)
  double precision :: u_yl(0:qx-1, 0:qy-1), u_yr(0:qx-1, 0:qy-1)
  double precision :: v_xl(0:qx-1, 0:qy-1), v_xr(0:qx-1, 0:qy-1)
  double precision :: v_yl(0:qx-1, 0:qy-1), v_yr(0:qx-1, 0:qy-1)

  nx = qx - 2*ng; ny = qy - 2*ng
  ilo = ng; ihi = ng+nx-1; jlo = ng; jhi = ng+ny-1
  
  ! u on x-edges
  dtdx = dt/dx

  do j = jlo-2, jhi+2
     do i = ilo-2, ihi+2        
        u_xl(i+1,j) = u(i,j) + 0.5d0*(1.0d0 - dtdx*u(i,j))*ldelta_ux(i,j)
        u_xr(i  ,j) = u(i,j) - 0.5d0*(1.0d0 + dtdx*u(i,j))*ldelta_ux(i,j)
     enddo
  enddo

  ! Riemann problem -- use utrans for the upwinding velocity.  The resulting
  ! quantity, u_xint, is what is used in the transverse difference
  call upwind(qx, qy, ng, &
              u_xl, u_xr, &
              utrans, &
              u_xint)


  ! v on x-edges -- needed for the transverse term
  do j = jlo-2, jhi+2
     do i = ilo-2, ihi+2        
        v_xl(i+1,j) = v(i,j) + 0.5d0*(1.0d0 - dtdx*u(i,j))*ldelta_vx(i,j)
        v_xr(i  ,j) = v(i,j) - 0.5d0*(1.0d0 + dtdx*u(i,j))*ldelta_vx(i,j)
     enddo
  enddo

  ! Riemann problem -- use utrans for the upwinding velocity.  The resulting
  ! quantity, u_xint, is what is used in the transverse difference
  call upwind(qx, qy, ng, &
              v_xl, v_xr, &
              utrans, &
              v_xint)


  ! u on y-edges -- needed for the transverse term
  dtdy = dt/dy

  do j = jlo-2, jhi+2
     do i = ilo-2, ihi+2        
        u_yl(i,j+1) = u(i,j) + 0.5d0*(1.0d0 - dtdy*v(i,j))*ldelta_uy(i,j)
        u_yr(i,j  ) = u(i,j) - 0.5d0*(1.0d0 + dtdy*v(i,j))*ldelta_uy(i,j)
     enddo
  enddo

  ! Riemann problem -- use vtrans for the upwinding velocity.  The resulting
  ! quantity, v_yint, is what is used in the transverse difference
  call upwind(qx, qy, ng, &
              u_yl, u_yr, &
              vtrans, &
              u_yint)


  ! v on y-edges
  do j = jlo-2, jhi+2
     do i = ilo-2, ihi+2        
        v_yl(i,j+1) = v(i,j) + 0.5d0*(1.0d0 - dtdy*v(i,j))*ldelta_vy(i,j)
        v_yr(i,j  ) = v(i,j) - 0.5d0*(1.0d0 + dtdy*v(i,j))*ldelta_vy(i,j)
     enddo
  enddo
  
  ! Riemann problem -- use vtrans for the upwinding velocity.  The resulting
  ! quantity, v_yint, is what is used in the transverse difference
  call upwind(qx, qy, ng, &
              v_yl, v_yr, &
              vtrans, &
              v_yint)


  ! add the transverse flux differences to the preliminary interface states
  do j = jlo-2, jhi+2
     do i = ilo-2, ihi+2        

        ubar = 0.5d0*(utrans(i,j) + utrans(i+1,j)
        vbar = 0.5d0*(vtrans(i,j) + vtrans(i,j+1))

        ! v du/dy is the transverse term for the u states on x-interfaces
        vu_y = vbar*(u_yint(i,j+1) - u_yint(i,j))
        
        u_xl(i+1,j) = u_xl(i+1,j) - 0.5*dtdy*vu_y - 0.5*dt*gradp_x(i,j)
        u_xr(i  ,j) = u_xr(i  ,j) - 0.5*dtdy*vu_y - 0.5*dt*gradp_x(i,j)

        ! v dv/dy is the transverse term for the v states on x-interfaces
        vv_y = vbar*(v_yint(i,j+1) - v_yint(i,j))

        v_xl(i+1,j) = v_xl(i+1,j) - 0.5*dtdy*vv_y - 0.5*dt*gradp_y(i,j)
        v_xr(i  ,j) = v_xr(i  ,j) - 0.5*dtdy*vv_y - 0.5*dt*gradp_y(i,j)

        ! u dv/dx is the transverse term for the v states on y-interfaces
        uv_x = ubar*(v_xint(i+1,j) - v_xint(i,j))

        v_yl(i,j+1) = v_yl(i,j+1) - 0.5*dtdx*uv_x - 0.5*dt*gradp_y(i,j)
        v_yr(i,j  ) = v_yr(i,j  ) - 0.5*dtdx*uv_x - 0.5*dt*gradp_y(i,j)

        ! u du/dx is the transverse term for the u states on y-interfaces
        uu_x = ubar*(u_xint(i+1,j) - u_xint(i,j))

        u_yl(i,j+1) = u_yl(i,j+1) - 0.5*dtdx*uu_x - 0.5*dt*gradp_x(i,j)
        u_yr(i,j  ) = u_yr(i,j  ) - 0.5*dtdx*uu_x - 0.5*dt*gradp_x(i,j)

     enddo
  enddo


  ! upwind using the MAC velocity to determine which state exists on the 
  ! interface

  call upwind(qx, qy, ng, &
              u_xl, u_xr, &
              u_MAC, &
              u_xint)

  call upwind(qx, qy, ng, &
              v_xl, v_xr, &
              u_MAC, &
              v_xint)

  call upwind(qx, qy, ng, &
              u_yl, u_yl, &
              v_MAC, &
              u_yint)

  call upwind(qx, qy, ng, &
              v_yl, v_yr, &
              v_MAC, &
              v_yint)
    
end subroutine states


!xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
subroutine upwind(qx, qy, ng, q_l, q_r, s, q_int)

  ! upwind the left and right states based on the specified input
  ! velocity, s.  The resulting interface state is q_int

  implicit none

  integer :: qx, qy, ng
  double precision :: q_l(0:qx-1, 0:qy-1), q_r(0:qx-1, 0:qy-1)
  double precision :: s(0:qx-1, 0:qy-1)
  double precision :: q_int(0:qx-1, 0:qy-1)

  integer :: ilo, ihi, jlo, jhi
  integer :: nx, ny
  integer :: i, j

  nx = qx - 2*ng; ny = qy - 2*ng
  ilo = ng; ihi = ng+nx-1; jlo = ng; jhi = ng+ny-1

  do j = jlo-1, jhi+1
     do i = ilo-1, ihi+1

        if (s(i,j) > 0.0d0) then
           q_int(i,j) = q_l(i,j)
        else if (s(i,j) == 0.0d0) then
           q_int(i,j) = 0.5d0*(q_l(i,j) + q_r(i,j))
        else
           q_int(i,j) = q_r(i,j)
        endif

     enddo
  enddo

end subroutine upwind


!xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
subroutine riemann_and_upwind(qx, qy, ng, q_l, q_r, q_int)

  ! Solve the Burger's Riemann problem given the input left and right
  ! states and use the resulting velocity through the interface to return
  ! the upwinded state, q_int.  (This differs from upwind, above, in that
  ! we don't take in a velocity to upwind with).
  !
  ! This uses the expressions from Almgren, Bell, and Szymczak 1996.

  implicit none

  integer :: qx, qy, ng
  double precision :: q_l(0:qx-1, 0:qy-1), q_r(0:qx-1, 0:qy-1)
  double precision :: q_int(0:qx-1, 0:qy-1)

  integer :: ilo, ihi, jlo, jhi
  integer :: nx, ny
  integer :: i, j

  double precision :: s

  nx = qx - 2*ng; ny = qy - 2*ng
  ilo = ng; ihi = ng+nx-1; jlo = ng; jhi = ng+ny-1

  do j = jlo-1, jhi+1
     do i = ilo-1, ihi+1

        if (q_l(i,j) > 0.0d0 .and. q_l(i,j) + q_r(i,j) > 0.0d0) then
           s = q_l(i,j)
        else if (q_l(i,j) <= 0.0d0 .and. q_r(i,j) >= 0.0d0) then
           s = 0.0d0
        else
           s = q_r(i,j)
        endif

        if (s > 0.0d0) then
           q_int(i,j) = q_l(i,j)
        else if (s == 0.0d0) then
           q_int(i,j) = 0.5d0*(q_l(i,j) + q_r(i,j))
        else
           q_int(i,j) = q_r(i,j)
        endif

     enddo
  enddo

end subroutine riemann_and_upwind
