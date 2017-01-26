/**
 * Created by Roman Lipovskiy on 18.01.2017.
 */
package
{
    import com.catalystapps.gaf.data.GAFTimeline;
    import com.catalystapps.gaf.display.GAFMovieClip;


    public dynamic class AnimatedFilters extends GAFMovieClip
    {

        public function AnimatedFilters(gafTimeline: GAFTimeline):void
        {
            super(gafTimeline);
            play(true);
        }

  
    }
}