!>@brief The module 'stochy_namelist_def' declares the variables to be read from the namelist
! and are publicly available

      module stochy_namelist_def
!
! program log
! 11 Oct 2016:    Philip Pegion create standalone stochastic physics
!
      use kinddef
      implicit none

      public
      integer, parameter :: max_n_var_lndp = 20 ! must match value used in GFS_typedefs
      integer, parameter :: max_n_var_spp  = 6 ! must match value used in GFS_typedefs
      integer nsspp,nssppt,nsshum,nsepbl,nsocnsppt,nsocnskeb,nsskeb,nslndp,lon_s,lat_s,ntrunc

! pjp stochastic phyics
      integer skeb_varspect_opt,skeb_npass
      logical sppt_sfclimit

      real(kind=kind_dbl_prec) :: skeb_sigtop1,skeb_sigtop2,          &
                         sppt_sigtop1,sppt_sigtop2,shum_sigefold, &
                         skeb_vdof
      real(kind=kind_dbl_prec) skeb_diss_smooth,sppint,spptint,shumint,skebint,skebnorm
      real(kind=kind_dbl_prec) epblint,ocnspptint,ocnskebint
      real(kind=kind_dbl_prec) lndpint
      real(kind=kind_dbl_prec), dimension(5) :: skeb,skeb_lscale,skeb_tau
      real(kind=kind_dbl_prec), dimension(5) :: sppt,sppt_lscale,sppt_tau
      real(kind=kind_dbl_prec), dimension(5) :: shum,shum_lscale,shum_tau
      real(kind=kind_dbl_prec), dimension(5) :: epbl,epbl_lscale,epbl_tau
      real(kind=kind_dbl_prec), dimension(5) :: ocnsppt,ocnsppt_lscale,ocnsppt_tau
      real(kind=kind_dbl_prec), dimension(5) :: ocnskeb,ocnskeb_lscale,ocnskeb_tau
      real(kind=kind_dbl_prec), dimension(7) :: pbl_taper
      integer,dimension(5) ::skeb_vfilt
      integer(kind=kind_dbl_prec),dimension(5) ::iseed_sppt,iseed_shum,iseed_skeb,iseed_epbl,iseed_ocnsppt,iseed_ocnskeb,iseed_epbl2
      logical stochini,sppt_logit,new_lscale
      logical use_zmtnblck
      logical do_shum,do_sppt,do_skeb,pert_epbl,do_ocnsppt,do_spp,do_ocnskeb

      real(kind=kind_dbl_prec), dimension(5) :: lndp_lscale,lndp_tau
      integer n_var_lndp
      integer(kind=8),dimension(5) ::iseed_lndp
      integer lndp_type
      integer lndp_model_type
      character(len=3), dimension(max_n_var_lndp)         ::  lndp_var_list
      real(kind=kind_dbl_prec), dimension(max_n_var_lndp) ::  lndp_prt_list

      real(kind=kind_dbl_prec), dimension(max_n_var_spp) :: spp_lscale    &
     &                                        , spp_tau,spp_stddev_cutoff &
     &                                        , spp_sigtop1, spp_sigtop2
      integer n_var_spp
      integer(8),dimension(max_n_var_spp) ::iseed_spp
      character(len=10), dimension(max_n_var_spp)         ::  spp_var_list
      real(kind=kind_dbl_prec), dimension(max_n_var_spp) ::  spp_prt_list

      end module stochy_namelist_def
