!>@brief The module 'compns_stochy_mod' contains the subroutine compns_stochy
module compns_stochy_mod

   implicit none

   contains

!-----------------------------------------------------------------------
!>@brief The module 'compns_stochy_mod' set the default namelist options reads in the stochastic physics namelist
!! and  sets logicals and other parameters based on the namelist
!>@details Namelist can be either a file, or an internal namelist
      subroutine compns_stochy (me,sz_nml,input_nml_file,fn_nml,nlunit,deltim,iret)
!$$$  Subprogram Documentation Block
!
! Subprogram:  compns     Check and compute namelist frequencies
!   Prgmmr: Iredell       Org: NP23          Date: 1999-01-26
!
! Abstract: This subprogram checks global spectral model namelist
!           frequencies in hour units for validity.  If they are valid,
!           then the frequencies are computed in timestep units.
!           The following rules are applied:
!             1. the timestep must be positive;
!
! Program History Log:
!   2016-10-11  Phil Pegion  make the stochastic physics stand alone
!
! Usage:    call compns_stochy (me,deltim,nlunit, stochy_namelist,iret)
!   Input Arguments:
!     deltim   - real timestep in seconds
!   Output Arguments:
!     iret     - integer return code (0 if successful or
!                between 1 and 8 for which rule above was broken)
!     stochy_namelist
!
! Attributes:
!   Language: Fortran 90
!
!$$$


      use stochy_namelist_def

      implicit none


      integer,              intent(out) :: iret
      integer,              intent(in)  :: nlunit,me,sz_nml
      character(len=*),     intent(in)  :: input_nml_file(sz_nml)
      character(len=64),    intent(in)  :: fn_nml
      real,                 intent(in)  :: deltim
      real tol,l_min
      real :: rerth,circ,tmp_lat
      integer k,ios
      integer,parameter :: four=4

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!
      namelist /nam_stochy/ntrunc,lon_s,lat_s,sppt,sppt_tau,sppt_lscale,sppt_logit, &
      iseed_shum,iseed_sppt,shum,shum_tau,                                          &
      shum_lscale,stochini,skeb_varspect_opt,sppt_sfclimit,                         &
      skeb,skeb_tau,skeb_vdof,skeb_lscale,iseed_skeb,skeb_vfilt,skeb_diss_smooth,   &
      skeb_sigtop1,skeb_sigtop2,skebnorm,sppt_sigtop1,sppt_sigtop2,                 &
      shum_sigefold,spptint,shumint,skebint,skeb_npass,use_zmtnblck,new_lscale,     &
      epbl,epbl_lscale,epbl_tau,iseed_epbl,                                         &
      ocnsppt,ocnsppt_lscale,ocnsppt_tau,iseed_ocnsppt,pbl_taper,                   &  
      ocnskeb,ocnskeb_lscale,ocnskeb_tau,iseed_ocnskeb

      namelist /nam_sfcperts/lndp_type,lndp_model_type, lndp_var_list, lndp_prt_list, & 
                            iseed_lndp,lndpint,lndp_tau,lndp_lscale 
!     For SPP physics parameterization perterbations
      namelist /nam_sppperts/spp_var_list, spp_prt_list, iseed_spp, &
      sppint,spp_tau,spp_lscale,spp_sigtop1,spp_sigtop2,spp_stddev_cutoff

      rerth  =6.3712e+6      ! radius of earth (m)
      tol=0.01  ! tolerance for calculations
!     spectral resolution defintion
      ntrunc=-999
      lon_s=-999
      lat_s=-999
      ! can specify up to 5 values for the stochastic physics parameters
      ! (each is an array of length 5)
      sppt             = -999.  ! stochastic physics tendency amplitude
      shum             = -999.  ! stochastic boundary layer spf hum amp
      skeb             = -999.  ! stochastic KE backscatter amplitude
      lndp_var_list  = 'XXX'
      lndp_prt_list  = -999.
      spp_var_list  = 'XXXXXXXXXX'
      spp_prt_list  = -999.
! logicals
      do_sppt = .false.
      use_zmtnblck = .false.
      new_lscale = .false.
      do_shum = .false.
      do_skeb = .false.
      do_spp  = .false.
! C. Draper July 2020.
! input land pert variables: 
! LNDP_TYPE = 0
! no explicit land perturbations
! LNDP_Type =  1 
! this is the initial land sfc pert scheme, introduced and tested for impact on GEFS forecasts.
! see https://journals.ametsoc.org/doi/full/10.1175/MWR-D-18-0057.1
! perturbations are assigned once at the start of the forecast
! LNDP_TYPE = 2
! this is the newer land pert scheme, introduced and tested for impact on UFS/GDAS cycling stsyem
! see https://journals.ametsoc.org/view/journals/hydr/22/8/JHM-D-21-0016.1.xml
      lndp_type = 0 !
! LNDP_MODEL_TYPE
! integer indicating the model type for applying perturbations for lndp_type=2 scheme.
! 1 - global model  
! (cycling of prognostic variables between DA cycles, 
!  parameters may be periodically updated during forecast)
! 2 - regional model 
! (short foreast, prognotic variables re-initialized each forecast, 
!  parameters not updated during forecast) 
! 3 - special case to apply perturbations only at start of forecast.
      lndp_model_type = 0 !
      lndp_lscale  = -999.       ! length scales
      lndp_tau     = -999.       ! time scales
      iseed_lndp   = 0           ! random seeds (if 0 use system clock)
! for SKEB random patterns.
      skeb_vfilt       = 0
      skebint          = 0
      spptint          = 0
      shumint          = 0
      skeb_npass       = 11  ! number of passes of smoother for dissipation estiamte
      sppt_tau         = -999.  ! time scales
      shum_tau         = -999.
      skeb_tau         = -999.
      skeb_vdof        = 5 ! proxy for vertical correlation, 5 is close to 40 passes of the 1-2-1 filter in the GFS
      skebnorm         = 0  ! 0 - random pattern is stream function, 1- pattern is kenorm, 2- pattern is vorticity, 3- normalized following Berner et al. 2009
      sppt_lscale      = -999.  ! length scales
      shum_lscale      = -999.
      skeb_lscale      = -999.
      iseed_sppt       = 0      ! random seeds (if 0 use system clock)
      iseed_shum       = 0
      iseed_skeb       = 0
! parameters to control vertical tapering of stochastic physics with
! height
      sppt_sigtop1 = 0.1
      sppt_sigtop2 = 0.025
      skeb_sigtop1 = 0.1
      skeb_sigtop2 = 0.025
      shum_sigefold = 0.2
      spp_sigtop1 = 0.1
      spp_sigtop2 = 0.025
! reduce amplitude of sppt near surface (lowest 2 levels)
      sppt_sfclimit = .false.
      pbl_taper = (/0.0,0.5,1.0,1.0,1.0,1.0,1.0/)
! gaussian or power law variance spectrum for skeb (0: gaussian, 1:
! power law). If power law, skeb_lscale interpreted as a power not a
! length scale.
      skeb_varspect_opt = 0
      sppt_logit        = .false. ! logit transform for sppt to bounded interval [-1,+1]
      stochini          = .false. ! true= read in pattern, false=initialize from seed
! For SPP perturbations
      spp_lscale  = -999.       ! length scales
      spp_tau     = -999.       ! time scales
      spp_stddev_cutoff = 0     ! cutoff/limit for std-dev (zero==no limit applied)
      iseed_spp   = 0           ! random seeds (if 0 use system clock)
      sppint      = 0           ! SPP interval in seconds
      lndpint     = 0           ! lndp interval in seconds

#ifdef INTERNAL_FILE_NML
      read(input_nml_file, nml=nam_stochy)
#else
      rewind (nlunit)
      open (unit=nlunit, file=fn_nml, action='READ', status='OLD', iostat=ios)
      read(nlunit,nam_stochy)
#endif
#ifdef INTERNAL_FILE_NML
      read(input_nml_file, nml=nam_sfcperts)
#else
      rewind (nlunit)
      open (unit=nlunit, file=fn_nml, action='READ', status='OLD', iostat=ios)
      read(nlunit,nam_sfcperts)
#endif

#ifdef INTERNAL_FILE_NML
      read(input_nml_file, nml=nam_sppperts, iostat=ios)
#else
      rewind (nlunit)
      open (unit=nlunit, file=fn_nml, action='READ', status='OLD', iostat=ios)
      read(nlunit,nam_sppperts)
      close(nlunit)
#endif

      if (me == 0) then
      print *,' in compns_stochy'
      print*,'spp_lscale=',spp_lscale
      print*,'spp_tau=',spp_tau
      print*,'spp_stddev_cutoff=',spp_stddev_cutoff
      endif

! PJP stochastic physics additions
      IF (sppt(1) > 0 ) THEN
        do_sppt=.true.
      ENDIF
      IF (shum(1) > 0 ) THEN
        do_shum=.true.
!     shum parameter has units of 1/hour, to remove time step
!     dependence.
!     change shum parameter units from per hour to per timestep
         DO k=1,5
            IF (shum(k) .gt. 0.0) shum(k)=shum(k)*deltim/3600.0
         ENDDO
      ENDIF
      IF (skeb(1) > 0 ) THEN
         do_skeb=.true.
         if (skebnorm==0) then ! stream function norm
            skeb=skeb*1.111e3*sqrt(deltim)
         endif
         if (skebnorm==1) then ! stream function norm
            skeb=skeb*0.00222*sqrt(deltim)
         endif
         if (skebnorm==2) then ! vorticty function norm
            skeb=skeb*1.111e-9*sqrt(deltim)
         endif
      ENDIF
      IF (spp_prt_list(1) > 0 ) THEN
         do_spp=.true.
      ENDIF
!    compute frequencty to estimate dissipation timescale
      IF (do_skeb) THEN
          IF (skebint == 0.) skebint=deltim
          nsskeb=nint(skebint/deltim)                              ! skebint in seconds
          IF(nsskeb<=0 .or. abs(nsskeb-skebint/deltim)>tol) THEN
             WRITE(0,*) "SKEB interval is invalid",skebint
            iret=9
            return
          ENDIF
      ENDIF 
      IF (do_sppt) THEN
          IF (spptint == 0.) spptint=deltim
          nssppt=nint(spptint/deltim)                              ! spptint in seconds
          IF(nssppt<=0 .or. abs(nssppt-spptint/deltim)>tol) THEN
             WRITE(0,*) "SPPT interval is invalid",spptint
            iret=9
            return
          ENDIF
      ENDIF 
      IF (do_shum) THEN
          IF (shumint == 0.) shumint=deltim
          nsshum=nint(shumint/deltim)                              ! shumint in seconds
          IF(nsshum<=0 .or. abs(nsshum-shumint/deltim)>tol) THEN
             WRITE(0,*) "SHUM interval is invalid",shumint
            iret=9
            return
          ENDIF
      ENDIF
      IF (do_spp) THEN
          IF (sppint == 0.) sppint=deltim
          nsspp=nint(sppint/deltim)                                ! sppint in seconds
          IF(nsspp<=0 .or. abs(nsspp-sppint/deltim)>tol) THEN
             WRITE(0,*) "SPP interval is invalid",sppint
            iret=9
            return
          ENDIF
      ENDIF

      IF (lndp_type > 0) THEN
          IF (lndpint == 0.) lndpint=deltim
          nslndp=nint(lndpint/deltim)       
          IF(nslndp<=0 .or. abs(nslndp-lndpint/deltim)>tol) THEN
             WRITE(0,*) "lndp interval is invalid",lndpint
            iret=9
            return
          ENDIF
      ENDIF

!calculate ntrunc if not supplied
     if (ntrunc .LT. 1) then  
        if (me==0) print*,'ntrunc not supplied, calculating'
        circ=2*3.1415928*rerth ! start with lengthscale that is circumference of the earth
        l_min=circ
        do k=1,5
           if (sppt(k).GT.0) l_min=min(sppt_lscale(k),l_min)
           if (shum(k).GT.0) l_min=min(shum_lscale(k),l_min)
           if (skeb(k).GT.0) l_min=min(skeb_lscale(k),l_min)
       enddo
       if (lndp_type.GT.0) l_min=min(lndp_lscale(1),l_min)
       if (spp_prt_list(1).GT.0) l_min=min(spp_lscale(1),l_min)
       !ntrunc=1.5*circ/l_min
       ntrunc=circ/l_min
       if (me==0) print*,'ntrunc calculated from l_min',l_min,ntrunc
     endif
     ! ensure lat_s is a mutiple of 4 with a reminader of two
     ntrunc=INT((ntrunc+1)/four)*four+2
     if (me==0) print*,'NOTE ntrunc adjusted for even nlats',ntrunc

! set up gaussian grid for ntrunc if not already defined. 
     if (lon_s.LT.1 .OR. lat_s.LT.1) then
        lat_s=ntrunc*1.5+1
        lon_s=lat_s*2+4
! Grid needs to be larger since interpolation is bi-linear
        lat_s=lat_s*2
        lon_s=lon_s*2
        if (me==0) print*,'gaussian grid not set, defining here',lon_s,lat_s
     endif

! 
! land perts  - parse nml input
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

     select case (lndp_type)
     case (0) 
        if (me==0) print*, & 
           'no land perturbations selected'
     case (1,2) 
        ! count requested pert variables
        n_var_lndp= 0
        do k =1,size(lndp_var_list)
            if  ( (lndp_var_list(k) .EQ. 'XXX') .or. (lndp_prt_list(k) .LE. 0.) ) then
               cycle
            else
                n_var_lndp=n_var_lndp+1
                lndp_var_list( n_var_lndp) = lndp_var_list(k)  
                lndp_prt_list( n_var_lndp) = lndp_prt_list(k) 
            endif
        enddo 
        if (n_var_lndp > max_n_var_lndp) then 
              print*, 'ERROR: land perturbation requested for too many parameters', & 
                       'increase max_n_var_lndp'
              iret = 10 
              return
        endif
                
      
        if (lndp_type==1) then  
          if (me==0) print*, & 
            'lndp_type=1, land perturbations will be applied to selected paramaters, using older scheme designed for S2S fcst spread with the noah LSM'
           !  sanity-check requested input
           do k =1,n_var_lndp
               select case (lndp_var_list(k))
               case('rz0','rzt','shc','lai','vgf','alb') 
                   if (me==0) print*, 'land perturbation will be applied to ', lndp_var_list(k)
               case default
                  print*, 'ERROR: land perturbation requested for unknown parameter', lndp_var_list(k)
                  iret = 10 
                  return
               end select 
           enddo
        elseif(lndp_type==2) then
            if (me==0) print*, & 
            'land perturbations will be applied to selected paramaters, using newer scheme designed for DA ens spread'
               ! check requested parameters have been coded. 
               ! note, Noah-MP specific checks will be done later (since need to know lsm type)
               do k =1,n_var_lndp
                   select case (lndp_var_list(k))
                   case('vgf','smc','stc','alb', 'sal','emi','zol') 
                       if (me==0) print*, 'land perturbation will be applied to ', lndp_var_list(k)
                   case default
                      print*, 'ERROR: land perturbation requested for new parameter - will need to be coded in lndp_apply_pert', lndp_var_list(k)
                      iret = 10 
                      return
                   end select 
               enddo
               if ( (lndp_model_type < 1) .or.  (lndp_model_type > 3) ) then 
                  print*, 'ERROR: for lndp_type=2, must have lndp_model_type = 1,2,3' 
                  iret = 10
                  return
               endif
        endif

     case default 
        if (me==0) print*, & 
         'lndp_type out of range, set to 0 (none), 1 (for fcst spread), 2 (for cycling DA spread)'
         iret = 10 
         return 
     end select 
! 
! SPP perts  - parse nml input
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     ! count requested pert variables
     n_var_spp= 0
     do k =1,size(spp_var_list)
         if  ( (spp_var_list(k) .EQ. 'XXXXXXXXXX') .or. (spp_prt_list(k) .LE. 0.) ) then
            cycle
         else
             n_var_spp=n_var_spp+1
             spp_var_list( n_var_spp) = spp_var_list(k)  ! 
             spp_prt_list( n_var_spp) = spp_prt_list(k)
         endif
     enddo
     IF (n_var_spp > 0 ) THEN
       do_spp=.true.
     ENDIF
     if (n_var_spp > max_n_var_spp) then
           print*, 'ERROR: SPP physics perturbation requested for too many parameters', &
                    'increase max_n_var_spp'
           iret = 10
           return
     endif
     if (me==0) print*, &
         'SPP physics perturbations will be applied to selected parameters', n_var_spp
        do k =1,n_var_spp
            select case (spp_var_list(k))
            case('pbl','sfc', 'mp','rad','gwd','cu_deep')
                if (me==0) print*, 'SPP physics perturbation will be applied to ', spp_var_list(k)
            case default
               print*, 'ERROR: SPP physics perturbation requested for new parameter - will need to be coded in spp_apply_pert', spp_var_list(k)
               iret = 10
               return
            end select
        enddo
!
!  All checks are successful.
!
      if (me == 0) then
         print *, 'stochastic physics'
         print *, ' do_sppt : ', do_sppt
         print *, ' do_shum : ', do_shum
         print *, ' do_skeb : ', do_skeb
         print *, ' lndp_type : ', lndp_type
         print *, ' lndp_model_type : ', lndp_model_type
         if (lndp_type .NE. 0) print *, ' n_var_lndp : ', n_var_lndp
         print *, ' do_spp  : ', do_spp
         print *, ' n_var_spp : ', n_var_spp
      endif
      iret = 0
!
      return
      end subroutine compns_stochy

      subroutine compns_stochy_ocn (deltim,iret)
!$$$  Subprogram Documentation Block
!
! Subprogram:  compns     Check and compute namelist frequencies
!   Prgmmr: Iredell       Org: NP23          Date: 1999-01-26
!
! Abstract: This subprogram checks global spectral model namelist
!           frequencies in hour units for validity.  If they are valid,
!           then the frequencies are computed in timestep units.
!           The following rules are applied:
!             1. the timestep must be positive;
!
! Program History Log:
!   2016-10-11  Phil Pegion  make the stochastic physics stand alone
!
! Usage:    call compns_stochy (me,deltim,nlunit, stochy_namelist,iret)
!   Input Arguments:
!     deltim   - real timestep in seconds
!   Output Arguments:
!     iret     - integer return code (0 if successful or
!                between 1 and 8 for which rule above was broken)
!     stochy_namelist
!
! Attributes:
!   Language: Fortran 90
!
!$$$


      use stochy_namelist_def
      use mpp_mod ,only: mpp_pe,mpp_root_pe

      implicit none


      real(kind=kind_dbl_prec),              intent(in)  :: deltim
      integer,              intent(out) :: iret
      real(kind=kind_dbl_prec) tol,l_min
      real(kind=kind_dbl_prec) :: rerth,circ
      integer k,ios,nlunit
      integer,parameter :: four=4

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!
      namelist /nam_stochy/ntrunc,lon_s,lat_s,sppt,sppt_tau,sppt_lscale,sppt_logit, &
      iseed_shum,iseed_sppt,shum,shum_tau,                                          &
      shum_lscale,stochini,skeb_varspect_opt,sppt_sfclimit,                         &
      skeb,skeb_tau,skeb_vdof,skeb_lscale,iseed_skeb,skeb_vfilt,skeb_diss_smooth,   &
      skeb_sigtop1,skeb_sigtop2,skebnorm,sppt_sigtop1,sppt_sigtop2,                 &
      shum_sigefold,spptint,shumint,skebint,skeb_npass,use_zmtnblck,new_lscale,     &
      epbl,epbl_lscale,epbl_tau,iseed_epbl,                                         &
      ocnsppt,ocnsppt_lscale,ocnsppt_tau,iseed_ocnsppt,pbl_taper,                   &
      ocnskeb,ocnskeb_lscale,ocnskeb_tau,iseed_ocnskeb

      namelist /nam_sfcperts/lndp_type,lndp_model_type,lndp_var_list, lndp_prt_list, iseed_lndp, & 
      lndp_tau,lndp_lscale 
      

      rerth  =6.3712e+6      ! radius of earth (m)
      tol=0.01  ! tolerance for calculations
      nlunit=322
!     spectral resolution defintion
      ntrunc=-999
      lon_s=-999
      lat_s=-999
      ! can specify up to 5 values for the stochastic physics parameters
      ! (each is an array of length 5)
      epbl             = -999.  ! stochastic physics tendency amplitude
      ocnsppt          = -999.  ! stochastic physics tendency amplitude
      ocnskeb          = -999.  ! stochastic physics tendency amplitude
! logicals
      pert_epbl = .false.
      do_ocnsppt = .false.
      do_ocnskeb = .false.
      new_lscale = .false.
      epblint          = 0
      ocnspptint       = 0
      ocnskebint       = 0
      epbl_tau         = -999.  ! time scales
      ocnsppt_tau      = -999.  ! time scales
      ocnskeb_tau      = -999.  ! time scales
      epbl_lscale      = -999.  ! length scales
      ocnsppt_lscale   = -999.  ! length scales
      ocnskeb_lscale   = -999.  ! length scales
      iseed_epbl       = 0      ! random seeds (if 0 use system clock)
      iseed_epbl2      = 0      ! random seeds (if 0 use system clock)
      iseed_ocnsppt    = 0      ! random seeds (if 0 use system clock)
      iseed_ocnskeb    = 0      ! random seeds (if 0 use system clock)
      rewind (nlunit)
      open (unit=nlunit, file='input.nml', action='READ', status='OLD', iostat=ios)
      read(nlunit,nam_stochy)
      close(nlunit)

      if (mpp_pe()==mpp_root_pe()) then
      print *,' in compns_stochy_ocn'
      endif

! PJP stochastic physics additions
      IF (epbl(1) > 0 ) THEN
        pert_epbl=.true.
      ENDIF
      IF (ocnsppt(1) > 0 ) THEN
        do_ocnsppt=.true.
      ENDIF
      IF (ocnskeb(1) > 0 ) THEN
        do_ocnskeb=.true.
      ENDIF
!    compute frequencty to update random pattern
      IF (epblint == 0.) epblint=deltim
      nsepbl=nint(epblint/deltim)                              ! epblint in seconds
      IF(nsepbl<=0 .or. abs(nsepbl-epblint/deltim)>tol) THEN
         WRITE(0,*) "ePBL interval is invalid",epblint
        iret=9
        return
      ENDIF
      IF (ocnspptint == 0.) ocnspptint=deltim
      nsocnsppt=nint(ocnspptint/deltim)                         ! ocnspptint in seconds
      IF(nsocnsppt<=0 .or. abs(nsocnsppt-ocnspptint/deltim)>tol) THEN
         WRITE(0,*) "ocnsppt interval is invalid",ocnspptint
        iret=9
        return
      ENDIF
      IF (ocnskebint == 0.) ocnskebint=deltim
      nsocnskeb=nint(ocnskebint/deltim)                         ! ocnskebint in seconds
      IF(nsocnskeb<=0 .or. abs(nsocnskeb-ocnskebint/deltim)>tol) THEN
         WRITE(0,*) "ocnskeb interval is invalid",ocnskebint
        iret=9
        return
      ENDIF
!calculate ntrunc if not supplied
     if (ntrunc .LT. 1) then  
        if (mpp_pe()==mpp_root_pe()) print*,'ntrunc not supplied, calculating'
        circ=2*3.1415928*rerth ! start with lengthscale that is circumference of the earth
        l_min=circ
        do k=1,5
           if (epbl(k).GT.0) l_min=min(epbl_lscale(k),l_min)
           if (ocnsppt(k).GT.0) l_min=min(ocnsppt_lscale(k),l_min)
           if (ocnskeb(k).GT.0) l_min=min(ocnskeb_lscale(k),l_min)
       enddo
       !ntrunc=1.5*circ/l_min
       ntrunc=circ/l_min
       if (mpp_pe()==mpp_root_pe()) print*,'ntrunc calculated from l_min',l_min,ntrunc
     endif
     ! ensure lat_s is a mutiple of 4 with a reminader of two
     ntrunc=INT((ntrunc+1)/four)*four+2
     if (mpp_pe()==mpp_root_pe()) print*,'NOTE ntrunc adjusted for even nlats',ntrunc

! set up gaussian grid for ntrunc if not already defined. 
     if (lon_s.LT.1 .OR. lat_s.LT.1) then
        lat_s=ntrunc*1.5+1
        lon_s=lat_s*2+4
! Grid needs to be larger since interpolation is bi-linear
        lat_s=lat_s*2
        lon_s=lon_s*2
        if (mpp_pe()==mpp_root_pe()) print*,'gaussian grid not set, defining here',lon_s,lat_s
     endif
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!
!  All checks are successful.
!
      if (mpp_pe()==mpp_root_pe()) then
         print *, 'ocean stochastic physics'
         print *, ' pert_epbl : ', pert_epbl
         print *, ' do_ocnsppt : ', do_ocnsppt
         print *, ' do_ocnskeb : ', do_ocnskeb
      endif
      iret = 0
      if (iseed_epbl(1) > 0) iseed_epbl2(1)=iseed_epbl(1)-1234567
!
      return
      end subroutine compns_stochy_ocn

end module compns_stochy_mod
