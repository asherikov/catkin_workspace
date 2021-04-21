/**
    @file
    @author  Alexander Sherikov

    @copyright 2020 Alexander Sherikov, Licensed under the Apache License,
    Version 2.0. (see @ref LICENSE or http://www.apache.org/licenses/LICENSE-2.0)

    @brief
*/

#include <ros/ros.h>

#include <staticoma/client.h>

#include <ariles2/visitors/yaml_cpp.h>
#include <ariles2/adapters/basic.h>
#include <ariles2/adapters/std_vector.h>
#include <ariles2/adapters/std_pair.h>
#include <ariles2/adapters/std_map.h>
#include <ariles2/ariles.h>
#include <ariles2/extra.h>

#include <staticoma/sources.h>


namespace
{
    class ParameterSubset : public ariles2::DefaultBase
    {
#define ARILES2_ENTRIES(v)                                                                                             \
    ARILES2_TYPED_ENTRY_(v, float_override, double)                                                                    \
    ARILES2_TYPED_ENTRY_(v, float_array_override, std::vector<double>)
#include ARILES2_INITIALIZE
    };

    class ParameterSet : public ariles2::SloppyBase
    {
#define ARILES2_ENTRIES(v)                                                                                             \
    ARILES2_TYPED_ENTRY_(v, parameter_subset, ParameterSubset)                                                         \
    ARILES2_ENTRY_(v, empty_array_override)                                                                            \
    ARILES2_TYPED_ENTRY_(v, integer_add, std::ptrdiff_t)                                                               \
    ARILES2_TYPED_ENTRY_(v, float_preserve, double)
#include ARILES2_INITIALIZE
    public:
        std::vector<std::pair<std::string, double>> empty_array_override_;
    };


    class DynamicParameters : public ariles2::DefaultBase
    {
#define ARILES2_ENTRIES(v)                                                                                             \
    ARILES2_TYPED_ENTRY_(v, int_param, std::ptrdiff_t)                                                                 \
    ARILES2_TYPED_ENTRY_(v, float_param, double)
#include ARILES2_INITIALIZE
    };
}  // namespace


int main(int argc, char **argv)
{
    ros::init(argc, argv, "package_c_node");
    ros::NodeHandle nh("~");

    try
    {
        staticoma::Client staticoma_client;

        std::cout << "===== RAW =====" << std::endl;
        {
            const std::string config = staticoma_client.getConfigString();
            std::cout << config << std::endl;
        }
        std::cout << "===============" << std::endl;


        std::cout << "===== parameter set =====" << std::endl;
        {
            ParameterSet parameter_set;

            ariles2::apply<ariles2::yaml_cpp::Reader>(staticoma_client.getConfigStream(), parameter_set, "parameter_set");
            ariles2::apply<ariles2::yaml_cpp::Writer>(std::cout, parameter_set);
        }
        std::cout << "=========================" << std::endl;


        std::cout << "===== parameter subset =====" << std::endl;
        {
            ParameterSubset parameter_subset;

            std::vector<std::string> subtree;
            subtree.push_back("parameter_set");
            subtree.push_back("parameter_subset");

            ariles2::apply<ariles2::yaml_cpp::Reader>(staticoma_client.getConfigStream(), parameter_subset, subtree);
            ariles2::apply<ariles2::yaml_cpp::Writer>(std::cout, parameter_subset, "parameter_subset");
        }
        std::cout << "============================" << std::endl;


        std::cout << "===== staticoma sources =====" << std::endl;
        staticoma::Sources sources;
        ariles2::apply<ariles2::yaml_cpp::Reader>(staticoma_client.getConfigStream(), sources);
        ariles2::apply<ariles2::yaml_cpp::Writer>(std::cout, sources);

        staticoma::Provider::NamedList providers = sources.select("dynamic_package_c_parameters");
        DynamicParameters dynamic_parameters;
        for (const staticoma::Provider::Named &provider : providers)
        {
            std::cout << "=== Processing provider " << staticoma::Provider::getName(provider) << std::endl;
            staticoma::Provider::readMessage(&dynamic_parameters, provider, ros::Duration(10.0));
            ariles2::apply<ariles2::yaml_cpp::Writer>(std::cout, dynamic_parameters);
        }
        std::cout << "=============================" << std::endl;
    }
    catch (const std::exception &e)
    {
        ROS_ERROR("Exception: %s", e.what());
        return (EXIT_FAILURE);
    }

    return (EXIT_SUCCESS);
}
