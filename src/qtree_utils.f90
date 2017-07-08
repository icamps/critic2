! Copyright (c) 2015 Alberto Otero de la Roza <aoterodelaroza@gmail.com>,
! Ángel Martín Pendás <angel@fluor.quimica.uniovi.es> and Víctor Luaña
! <victor@fluor.quimica.uniovi.es>. 
!
! critic2 is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or (at
! your option) any later version.
! 
! critic2 is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
! 
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see <http://www.gnu.org/licenses/>.

!> Qtree, utilities.
module qtree_utils
  implicit none

  private
  public :: small_writetess
  public :: open_difftess
  public :: close_difftess
  public :: getkeast

contains

  !> Write a .tess file containing the color information on the grid.
  !> Optionally, represent only the outer (visible) balls.
  subroutine small_writetess(roottess,otrm,trm)
    use systemmod, only: sy
    use qtree_basic, only: qtreei, minlen, maxl, nnuc, cindex,&
       torig, tvec, lrotm, leqv, nt_orig
    use global, only: ws_origin, plot_mode, fileroot, plotsticks
    use tools_io, only: fopen_write, fclose
    use param, only: maxzat0, jmlcol, jmlcol2

    character*50, intent(in) :: roottess
    integer, intent(in) :: otrm
    integer(qtreei), intent(in) :: trm(:,:)

    integer :: luo
    integer :: i
    character*2 :: label
    integer :: tt, h, k, l, m, l2, zz
    real*8 :: xp1(3), xp2(3)
    integer :: nvr, nballs, vin(3), trmi, trmj, type, lend
    logical :: plotit, eqt
    real*8 :: clip0(3), clip1(3)
    character*50 :: rootloc

    real*8 :: diab

    luo = fopen_write(trim(roottess) // ".tess")

    nvr = size(trm,1) * nt_orig
    nballs = nvr
    do i = 1, sy%f(sy%iref)%ncp
       if (sy%f(sy%iref)%cp(i)%typ /= sy%f(sy%iref)%typnuc) cycle
       nballs = nballs + 1
    end do

    ! header
    write (luo,'("#")')
    write (luo,'("# Tessel file generated by critic (qtree)")')
    write (luo,'("#")')
    write (luo,'(A)') "set camangle 75 -10 45"
    write (luo,'(A)') "set background background {color rgb <1,1,1>}"
    write (luo,'(A)') "set use_planes .false."
    write (luo,'(A)') "set ball_texture finish{specular 0.2 roughness 0.1 reflection 0.1}"
    write (luo,'(A)') "set equalscale noscale"
    write (luo,'(A)') "molecule"
    write (luo,'(X,A)') "crystal"
    write (luo,'(2X,A)') "title qtree integration."
    write (luo,'(2X,A)') "symmatrix seitz"
    do i = 1, sy%c%ncv
       write (luo,'(3X,A,3(F15.12,X))') "cen ",sy%c%cen(:,i)
    end do
    write (luo,'(3X,A)') "#"
    do i = 1, sy%c%neqv
       write (luo,'(3X,3(F5.2,X),F15.12)') sy%c%rotm(1,:,i)
       write (luo,'(3X,3(F5.2,X),F15.12)') sy%c%rotm(2,:,i)
       write (luo,'(3X,3(F5.2,X),F15.12)') sy%c%rotm(3,:,i)
       write (luo,'(3X,A)') "#"
    end do
    write (luo,'(2X,A)') "endsymmatrix"
    write (luo,'(2X,A,6(F10.6" "))') "cell", sy%c%aa, sy%c%bb
    write (luo,'(2X,A)') "crystalbox  -2.30 -2.30 -2.30 2.30 2.30 2.30"
    clip0 = (/-0.5d0,-0.5d0,-0.5d0/) + ws_origin
    clip1 = (/0.5d0,0.5d0,0.5d0/) + ws_origin
    write (luo,'(2X,A,6(F10.4,X))') "clippingbox ", clip0, clip1
    do i = 1, sy%f(sy%iref)%ncp
       if (i <= sy%c%nneq) then
          label = trim(sy%c%at(i)%name)
          if (label(2:2) == " ") label(2:2) = "_"
       else if (sy%f(sy%iref)%cp(i)%typ == -3) then
          label = "XX"
       else if (sy%f(sy%iref)%cp(i)%typ == -1)  then
          label = "YY"
       else if (sy%f(sy%iref)%cp(i)%typ == 1) then
          label = "ZZ"
       else
          label = "XZ"
       end if
       write (luo,'(2X,A,3(F10.6," "),A2,I2.2,a)') &
          "neq ",sy%f(sy%iref)%cp(i)%x,label,i," 0"
    end do
    write (luo,'(X,A)') "endcrystal"
    if (plot_mode == 3 .or. plot_mode == 4 .or. plot_mode == 5) then
       write (luo,'(X,A,3(F10.4,X))') "wigner_seitz edges radius 0.01 at ", ws_origin
    else
       write (luo,'(X,A,3(F10.4,X))') "wigner_seitz edges irreducible radius 0.01 at ", ws_origin
    end if
    do i = 1, sy%f(sy%iref)%ncp
       if (i <= sy%c%nneq) then
          label = trim(sy%c%at(i)%name)
          if (label(2:2) == " ") label(2:2) = "_"
       else if (sy%f(sy%iref)%cp(i)%typ == -3) then
          label = "XX"
       else if (sy%f(sy%iref)%cp(i)%typ == -1)  then
          label = "YY"
       else if (sy%f(sy%iref)%cp(i)%typ == 1) then
          label = "ZZ"
       else
          label = "XZ"
       end if
       if (i <= sy%c%nneq) then
          write (luo,'(X,A5,A,I2.2,A)') "ball ",label,i," jmol radius 0.2"
       else
          write (luo,'(X,A5,A,I2.2,A)') "ball ",label,i," jmol radius 0.1"
       end if
    end do
    write (luo,'(X,A)') "freehand"

    diab = minlen / 2**maxl / 3d0
    do i = 1, nnuc+3
       if (i <= nnuc) then
          zz = sy%c%at(i)%z
       else if (i == nnuc+1) then
          zz = 1
       else
          zz = maxzat0
       end if
       write (luo,'(2X,A,I4,A,F10.6,A,3(F6.2,X))') &
          "type ", 2*i-1, " pointrad ", diab, " pointrgb ", real(JMLcol(:,zz),8)/255d0
       write (luo,'(2X,A,I4,A,F10.6,A,3(F6.2,X))') &
          "type ", 2*i, " pointrad ", diab, " pointrgb ", real(JMLcol2(:,zz),8)/255d0
    end do
    
    if (plot_mode == 3 .or. plot_mode == 4 .or. plot_mode == 5) then
       lend = leqv
    else
       lend = 1
    end if
    ! balls
    l2 = 2**maxl
    do tt = 1, nt_orig
       do h = 0, l2
          do k = 0, l2-h
             do l = 0, l2-h-k
                plotit = .true.
                vin = (/h, k, l/)
                trmi = trm(cindex(vin,maxl),tt)
                if (otrm /= 0 .and. abs(trmi) /= otrm) cycle
                if (plot_mode == 2 .or. plot_mode == 5) then
                   if (h/=0 .and. h/=l2 .and. k/=0 .and. k/=l2 .and.&
                       l/=0 .and. l/=l2 .and. (h+k+l)/=0 .and. (h+k+l)/=l2) then
                      eqt = .true.
                      vin = (/h+1,k,l/)
                      trmj = trm(cindex(vin,maxl),tt)
                      eqt = eqt .and. (trmi==trmj)
                      vin = (/h-1,k,l/)
                      trmj = trm(cindex(vin,maxl),tt)
                      eqt = eqt .and. (trmi==trmj)
                      vin = (/h,k+1,l/)
                      trmj = trm(cindex(vin,maxl),tt)
                      eqt = eqt .and. (trmi==trmj)
                      vin = (/h,k-1,l/)
                      trmj = trm(cindex(vin,maxl),tt)
                      eqt = eqt .and. (trmi==trmj)
                      vin = (/h,k,l+1/)
                      trmj = trm(cindex(vin,maxl),tt)
                      eqt = eqt .and. (trmi==trmj)
                      vin = (/h,k,l-1/)
                      trmj = trm(cindex(vin,maxl),tt)
                      eqt = eqt .and. (trmi==trmj)
                      plotit = .not.eqt
                   end if
                end if
                if (plotit) then
                   xp1 = torig(:,tt)
                   xp1 = xp1 + tvec(:,1,tt) * real(h,8) / l2
                   xp1 = xp1 + tvec(:,2,tt) * real(k,8) / l2
                   xp1 = xp1 + tvec(:,3,tt) * real(l,8) / l2
                   if (trmi <= 0) then
                      type = 2 * abs(trmi)
                   else
                      type = 2 * abs(trmi) - 1
                   end if
                   do m = 1, lend
                      xp2 = matmul(lrotm(:,1:3,m),xp1-ws_origin) + ws_origin
                      write (luo,'(2X,"ball ",3(F10.6,X),"type ",I2)') &
                         xp2(1), xp2(2), xp2(3), type
                   end do
                end if
             end do
          end do
       end do
    end do
    if (plot_mode > 0 .and. plotsticks) then
       do i = 0, maxl
          write (rootloc,'(A,A,I2.2,A,I2.2)') trim(fileroot),"_level",maxl,".",i
          write (luo,'(2X,"arrows file ",A)') trim(rootloc) // ".stick"
       end do
    end if

    write (luo,'(X,A)') "endfreehand"
    write (luo,'(X,3A)') "# vrml ", trim(roottess), ".wrl"
    write (luo,'(X,3A)') "povray ", trim(roottess), ".pov"
    write (luo,'(A)') "endmolecule"
    write (luo,'(5A)') "run povray -d +ft +I", trim(roottess), ".pov +O", trim(roottess), ".tga +W2000 +H2000 +A"
    write (luo,'(5A)') "run convert ", &
       trim(roottess), ".tga -bordercolor white -border 1x1 -trim +repage ", trim(roottess), ".png"
    write (luo,'(3A)') "run rm -f ", trim(roottess), ".tga"
    write (luo,'(A)') "reset"
    write (luo,'(A)') "end"

    call fclose(luo)

  end subroutine small_writetess

  !> Open and write the header of a tessel input file.
  subroutine open_difftess(roottess)
    use systemmod, only: sy
    use qtree_basic, only: ludif, minlen, maxl
    use global, only: gradient_mode, qtree_ode_mode, ws_origin
    use tools_io, only: fopen_write

    character*50, intent(in) :: roottess

    integer :: i
    character*2 :: label
    real*8 :: clip0(3), clip1(3)

    real*8 :: diab

    ludif = fopen_write(trim(roottess) // ".tess")

    ! header
    write (ludif,'("#")')
    write (ludif,'("# Tessel file generated by critic (qtree)")')
    write (ludif,'("# Term. differences at gradient_mode = ",I2)') gradient_mode
    write (ludif,'("# qtree_ode_mode = ",I2)') qtree_ode_mode
    write (ludif,'("#")')
    write (ludif,'(A)') "set camangle 75 -10 45"
    write (ludif,'(A)') "set background background {color rgb <1,1,1>}"
    write (ludif,'(A)') "set use_planes .false."
    write (ludif,'(A)') "set ball_texture finish{specular 0.2 roughness 0.1 reflection 0.1}"
    write (ludif,'(A)') "set equalscale noscale"
    write (ludif,'(A)') "molecule"
    write (ludif,'(X,A)') "crystal"
    write (ludif,'(2X,A)') "title qtree integration."
    write (ludif,'(2X,A)') "symmatrix seitz"
    do i = 1, sy%c%ncv
       write (ludif,'(3X,A,3(F15.12,X))') "cen ",sy%c%cen(:,i)
    end do
    write (ludif,'(3X,A)') "#"
    do i = 1, sy%c%neqv
       write (ludif,'(3X,3(F5.2,X),F15.12)') sy%c%rotm(1,:,i)
       write (ludif,'(3X,3(F5.2,X),F15.12)') sy%c%rotm(2,:,i)
       write (ludif,'(3X,3(F5.2,X),F15.12)') sy%c%rotm(3,:,i)
       write (ludif,'(3X,A)') "#"
    end do
    write (ludif,'(2X,A)') "endsymmatrix"
    write (ludif,'(2X,A,6(F10.6" "))') "cell", sy%c%aa, sy%c%bb
    write (ludif,'(2X,A)') "crystalbox  -2.30 -2.30 -2.30 2.30 2.30 2.30"
    clip0 = (/-0.5d0,-0.5d0,-0.5d0/) + ws_origin
    clip1 = (/0.5d0,0.5d0,0.5d0/) + ws_origin
    write (ludif,'(2X,A,6(F10.4,X))') "clippingbox ", clip0, clip1
    do i = 1, sy%f(sy%iref)%ncp
       if (i <= sy%c%nneq) then
          label = trim(sy%c%at(i)%name)
          if (label(2:2) == " ") label(2:2) = "_"
       else if (sy%f(sy%iref)%cp(i)%typ == -3) then
          label = "XX"
       else if (sy%f(sy%iref)%cp(i)%typ == -1)  then
          label = "YY"
       else if (sy%f(sy%iref)%cp(i)%typ == 1) then
          label = "ZZ"
       else
          label = "XZ"
       end if
       write (ludif,'(2X,A,3(F10.6," "),A2,I2.2,a)') &
          "neq ",sy%f(sy%iref)%cp(i)%x,label,i," 0"
    end do
    write (ludif,'(X,A)') "endcrystal"
    write (ludif,'(X,A,3(F10.4,X))') "wigner_seitz edges irreducible radius 0.01 at ", ws_origin
    do i = 1, sy%f(sy%iref)%ncp
       if (i <= sy%c%nneq) then
          label = trim(sy%c%at(i)%name)
          if (label(2:2) == " ") label(2:2) = "_"
       else if (sy%f(sy%iref)%cp(i)%typ == -3) then
          label = "XX"
       else if (sy%f(sy%iref)%cp(i)%typ == -1)  then
          label = "YY"
       else if (sy%f(sy%iref)%cp(i)%typ == 1) then
          label = "ZZ"
       else
          label = "XZ"
       end if
       if (i <= sy%c%nneq) then
          write (ludif,'(X,A5,A,I2.2,A)') "ball ",label,i," jmol radius 0.2"
       else
          write (ludif,'(X,A5,A,I2.2,A)') "ball ",label,i," jmol radius 0.1"
       end if
    end do
    write (ludif,'(X,A)') "freehand"

    diab = minlen / 2**maxl / 3d0
    write (ludif,'(A,F10.6,A)') "type 1 pointrad ", diab, " pointrgb 0.8 0.8 0.8"
    
  end subroutine open_difftess

  !> Write the ending and close a tessel input file.
  subroutine close_difftess(roottess)
    use qtree_basic, only: ludif
    use tools_io, only: fclose

    character*50, intent(in) :: roottess

    write (ludif,'(X,A)') "endfreehand"
    write (ludif,'(X,3A)') " vrml ", trim(roottess), ".wrl"
    write (ludif,'(X,3A)') "# povray ", trim(roottess), ".pov"
    write (ludif,'(A)') "endmolecule"
    write (ludif,'(5A)') "#run povray -d +ft +I", trim(roottess), ".pov +O", trim(roottess), ".tga +W2000 +H2000 +A"
    write (ludif,'(5A)') "#run convert ",&
       trim(roottess), ".tga -bordercolor white -border 1x1 -trim +repage ", trim(roottess), ".png"
    write (ludif,'(3A)') "#run rm -f ", trim(roottess), ".tga"
    write (ludif,'(A)') "reset"
    write (ludif,'(A)') "end"

    call fclose(ludif)

  end subroutine close_difftess

  !> Load and output information about the keast cuadratures.
  subroutine getkeast()
    use keast, only: keast_rule_num, keast_order_num
    use tools_io, only: uout
    
    integer*4 :: num
    integer*4 :: i, order
    integer, parameter :: kprec(10) = (/0, 1, 2, 3, 4, 4, 5, 6, 7, 8/)
    
    call keast_rule_num(num)

    write (uout,'("* KEAST integration routines, by J. Burkardt et al. (see keast/)")')
    write (uout,'("* Ref: P.Keast, Comp. Methods Appl. Mech. Eng. 55(3) (1986) 339--348")')
    write (uout,'("* Rule number and associated integration orders and precisions ")')

    do i = 1, num
       call keast_order_num(i,order)
       write (uout,'(" Rule ",I2"   order = ",I2," prec = ",I2)') i, order, kprec(i)
    end do
    write (uout,*)

  end subroutine getkeast

end module qtree_utils
