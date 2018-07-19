defmodule Math.Vec do 

    defmacro __using__(_) do
        quote do 
            require Math.Vec.Vec3
            alias Math.Vec.Vec3
            require Math.Vec.Vec4 
            alias Math.Vec.Vec4
        end
    end 




    defmodule  Vec3 do
          @doc """
            reutnr vec3
        """
        @spec new(x:: any, y:: any, z:: any) :: map
        def new(x,y,z) do 
            %{x: x, y: y, z: z}
        end


        #-> integer
        def length_squared(v1,v2) do 
            (v1.x-v2.x)*(v1.x-v2.x) + (v1.y-v2.y)*(v1.y-v2.y) + (v1.z-v2.z)*(v1.z-v2.z)
        end
        

          #-> integer
        def length(v1,v2) do 
            :math.sqrt(length_squared(v1,v2))
        end


    end



    defmodule Vec4 do 

        @doc """
            reutnr vec4
        """
        @spec new(x:: any, y:: any, z:: any, w:: any) :: map
        def new(x,y,z,w) do 
             %{x: x, y: y, z: z, w: w}
        end
    end

end

